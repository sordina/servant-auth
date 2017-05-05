{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE OverlappingInstances #-}

module Servant.Auth.Swagger
  (
  -- | The purpose of this package is provide the instance for 'servant-auth'
  -- combinators needed for 'servant-swagger' documentation generation.
  --
  -- Currently only JWT and BasicAuth are supported.

  -- * Re-export
    JWT
  , BasicAuth
  , Auth
  ) where

import Control.Lens    ((&), (<>~))
import Data.Proxy      (Proxy (Proxy))
import Data.Swagger    (ApiKeyLocation (..), ApiKeyParams (..),
                        SecurityRequirement (..), SecurityScheme (..),
                        SecuritySchemeType (..), allOperations, security,
                        securityDefinitions)
import GHC.Exts        (fromList)
import Servant.API     hiding (BasicAuth)
import Servant.Auth
import Servant.Swagger

import qualified Data.Text as T

instance (AllHasSecurity xs, HasSwagger api) => HasSwagger (Auth xs r :> api) where
  toSwagger _
    = toSwagger (Proxy :: Proxy api)
        & securityDefinitions <>~ fromList secs
        & allOperations.security <>~ secReqs
    where
      secs = securities (Proxy :: Proxy xs)
      secReqs = [ SecurityRequirement (fromList [(s,[])]) | (s,_) <- secs]


class HasSecurity x where
  securityName :: Proxy x -> T.Text
  securityScheme :: Proxy x -> SecurityScheme

instance HasSecurity BasicAuth where
  securityName _ = "BasicAuth"
  securityScheme _ = SecurityScheme type_ (Just desc)
    where
      type_ = SecuritySchemeBasic
      desc  = "Basic access authentication"

instance HasSecurity JWT where
  securityName _ = "JwtSecurity"
  securityScheme _ = SecurityScheme type_ (Just desc)
    where
      type_ = SecuritySchemeApiKey (ApiKeyParams "Authorization" ApiKeyHeader)
      desc  = "JSON Web Token-based API key"

class AllHasSecurity (x :: [*]) where
  securities :: Proxy x -> [(T.Text,SecurityScheme)]

instance (HasSecurity x, AllHasSecurity xs) => AllHasSecurity (x ': xs) where
  securities _ = (securityName px, securityScheme px) : securities pxs
    where
      px :: Proxy x
      px = Proxy
      pxs :: Proxy xs
      pxs = Proxy

instance AllHasSecurity xs => AllHasSecurity (x ': xs) where
  securities _ = securities pxs
    where
      pxs :: Proxy xs
      pxs = Proxy

instance AllHasSecurity '[] where
  securities _ = []
