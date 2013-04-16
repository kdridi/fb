{-# LANGUAGE DeriveDataTypeable, FlexibleContexts, OverloadedStrings #-}
module Facebook.Object.Order
	( Order(..)
	, OrderStatus(..)
	, OrderApplication(..)
	) where

import Control.Applicative
import Control.Monad (mzero)
import Control.Monad.Trans.Control (MonadBaseControl)
import Data.Text (Text)
import Data.Aeson ((.:), (.:?))
import Data.Typeable (Typeable)

import qualified Data.Aeson as A
import qualified Data.Conduit as C

import Facebook.Types
import Facebook.Monad
import Facebook.Graph

-- | Order Id type
type OrderId = Id

-- | A Facebook Order oject
data Order = Order {
	orderId   	:: OrderId,
	orderFrom 	:: UserId,
	orderTo	  	:: UserId,
	orderAmount :: Integer,
	orderStatus :: OrderStatus,
	orderApplication 	:: OrderApplication,
	orderCountry		:: Text,
	orderRefundCode		:: Maybe Text,
	orderCreatedTime 	:: Maybe Text,
	orderUpdatedTime	:: Maybe Text
} deriving (Show, Typeable)

-- | A Facebook Order status type
data OrderStatus = 
	OrderPlaced 
	| OrderSettled 
	| OrderRefunded 
	| OrderDisputed 
	| OrderCancelled
	deriving (Show, Enum, Eq, Typeable)

-- | A trimmed down version of Facebook Application as it is used in Order
data OrderApplication = OrderApplication {
	appId 	:: Text,
	appName	:: Text
} deriving (Show, Typeable)

instance A.FromJSON OrderApplication where
	parseJSON (A.Object v) 	=
		OrderApplication 	<$> v .: "id"
						 	<*> v .: "name"
	parseJSON _ 			= mzero 

instance A.FromJSON Order where
	parseJSON (A.Object v) =
		Order <$> v .: "id"
			  <*> v .: "from"
			  <*> v .: "to"
			  <*> v .: "amount"
			  <*> v .: "status"
			  <*> v .: "application"
			  <*> v .: "country"
			  <*> v .:? "refund_reason_code"
			  <*> v .:? "created_time"
			  <*> v .:? "updated_time"
	parseJSON _ = mzero

instance A.FromJSON OrderStatus where
	parseJSON (A.String "placed") 		= return OrderPlaced
	parseJSON (A.String "settled") 		= return OrderSettled
	parseJSON (A.String "refunded")		= return OrderRefunded
	parseJSON (A.String "disputed")		= return OrderDisputed
	parseJSON (A.String "cancelled")	= return OrderCancelled
	parseJSON _							= mzero

-- | Get an order using order ID.  The user access token is
-- mandatory. 
getOrder :: (C.MonadResource m, MonadBaseControl IO m) =>
           OrderId         -- ^ Order ID.
        -> UserAccessToken -- ^ Optional user access token.
        -> FacebookT anyAuth m Order
getOrder id_ mtoken = getObject ("/" <> idCode id_) [] (Just mtoken)