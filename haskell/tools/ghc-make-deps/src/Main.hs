-- |
module Main (main) where

import GHC
import GHC.Driver.Session (defaultFatalMessager, defaultFlushOut)
import GHC.SysTools.BaseDir (findTopDir)
import MakeDeps.MakeFile
import System.Environment (getArgs)

main :: IO ()
main = do
    (outdir : args) <- getArgs
    topdir <- findTopDir Nothing
    defaultErrorHandler defaultFatalMessager defaultFlushOut $ do
        runGhc (Just topdir) $ do
            dflags <- getSessionDynFlags
            logger <- getLogger
            (dflags1, fileish_args, _dynamicFlagWarnings) <- parseDynamicFlags logger dflags (map noLoc args)
            setSessionDynFlags dflags1

            doMkDependHS [outdir] (map ((, Nothing) . unLoc) fileish_args)
