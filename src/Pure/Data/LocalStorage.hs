{-# LANGUAGE CPP, OverloadedStrings, ViewPatterns #-}
module Pure.Data.LocalStorage (get, put, delete, clear) where

-- from base
import Data.IORef
import System.IO.Unsafe

-- from pure-json
import Pure.Data.JSON

-- from pure-lifted
import Pure.Data.Lifted hiding (clear)

-- from pure-txt
import Pure.Data.Txt

-- from unordered-containers
import qualified Data.HashMap.Strict as HashMap

#ifdef __GHCJS__
foreign import javascript unsafe
  "try { window.localStorage.setItem($1, $2); $r = 1; } catch (e) { $r = 0; }"
  set_item_catch_js :: Txt -> Txt -> IO Int

foreign import javascript unsafe
  "window.localStorage.removeItem($1);" remove_item_js :: Txt -> IO ()

foreign import javascript unsafe
  "window.localStorage.clear()" clear_local_storage_js :: IO ()

-- foreign import javascript unsafe
--   "var arr = []; for (var i = 0, len = window.localStorage.length; i < len; i++) { var key = window.localStorage.key(i); var value = window.localStorage[key]; arr.push({ key: key, value: value }); }; $r = arr;"
--   read_local_storage_js :: IO JSA.JSArray

foreign import javascript unsafe
  "$r = window.localStorage.getItem($1)" get_item_js :: Txt -> IO Txt

foreign import javascript unsafe
  "LZString.compress($1)" compress :: Txt -> IO Txt

foreign import javascript unsafe
  "LZString.decompress($1)" decompress :: Txt -> IO Txt
#endif

#ifndef __GHCJS__
{-# NOINLINE localStorage #-}
localStorage :: IORef (HashMap.HashMap Txt Value)
localStorage = unsafePerformIO $ newIORef HashMap.empty
#endif

get :: FromJSON a => Txt -> IO (Maybe a)
get key = do
#ifdef __GHCJS__
  txt <- get_item_js key
  if isNull (toJSV txt)
    then return Nothing
    else do
      val <- fmap js_JSON_parse $ decompress txt
      case fromJSON val of
        Error   _ -> return Nothing
        Success a -> return $ Just a
#else
  ls <- readIORef localStorage
  case HashMap.lookup key ls of
    Just (fromJSON -> Success a) -> return (Just a)
    _                            -> return Nothing
#endif

put :: ToJSON a => Txt -> a -> IO Bool
put k v = do
#ifdef __GHCJS__
  txt <- compress (toTxt (toJSON v))
  res <- set_item_catch_js k txt
  return (res /= 0)
#else
  modifyIORef localStorage (HashMap.insert k (toJSON v))
  return True
#endif

delete :: Txt -> IO ()
delete k = do
#ifdef __GHCJS__
  remove_item_js k
#else
  modifyIORef localStorage (HashMap.delete k)
#endif

clear :: IO ()
#ifdef __GHCJS__
clear = clear_local_storage_js
#else
clear = writeIORef localStorage HashMap.empty
#endif
