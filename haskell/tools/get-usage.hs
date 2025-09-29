{-# LANGUAGE NamedFieldPuns #-}
import GHC
import GHC.Utils.Panic
import GHC.Iface.Binary
import GHC.Platform
import GHC.Platform.Profile
import GHC.Plugins (unitIdString, mi_usages)
import GHC.Types.Name.Cache
import GHC.Unit.Module.Deps
import qualified Data.Set as Set
import System.Environment
import System.IO (hPutStrLn, stderr)
import System.Exit (exitFailure)

-- NOTE for GHC 9.13

getInterface ifaceFile = do
  let profile = Profile { profilePlatform = genericPlatform, profileWays = Set.empty }

  -- TODO initNameCache is deprecated, newNameCache is available with GHC > 9.12.x
  -- name_cache <- newNameCache
  name_cache <- initNameCache 'x' []

  -- Load the interface file
  tryMost $ readBinIface profile name_cache IgnoreHiWay QuietBinIFace ifaceFile

main :: IO ()
main = do
  args <- getArgs
  case args of
    [ifaceFile] -> do
        let on_home_mod_usage (UsageHomeModule {usg_mod_name, usg_unit_id}) acc =
              -- (unitIdString usg_unit_id) <> " " <> (moduleNameString usg_mod_name) <> " / " <> concat (("\n - " ++) . occNameString . fst <$> usg_entities) <> usedExports : acc
              (unitIdString usg_unit_id) <> " " <> (moduleNameString usg_mod_name) : acc

            on_home_mod_usage (UsagePackageModule {}) acc = acc
            --on_home_mod_usage (UsagePackageModule {usg_mod, usg_safe}) acc =
            -- (show $ moduleUnit usg_mod) : acc

            on_home_mod_usage (UsageHomeModuleInterface {}) acc = acc -- (used for template haskell)
            on_home_mod_usage (UsageMergedRequirement {}) acc = acc
            on_home_mod_usage (UsageFile {}) acc = acc
        target <- getInterface ifaceFile

        case target of
          Right iface -> do
            let usages = mi_usages iface
                --abihash = mi_mod_hash iface
                result = case usages of
                  Just usages' -> foldr (on_home_mod_usage) [] usages'
                  Nothing -> []
            --putStrLn $ "ABI hash: " <> show abihash
            putStrLn $ unlines result
          Left msg -> do
            hPutStrLn stderr $ show msg
            exitFailure

    _ -> do
      putStrLn $ "Usage: usagefiles <interface_file>"
      exitFailure
