-- | A module providing a type and operations for the native JavaScript `Date`
-- | object.
-- |
-- | The `JSDate` type and associated functions are provided for interop
-- | purposes with JavaScript, but for working with dates in PureScript it is
-- | recommended that `DateTime` representation is used instead - `DateTime`
-- | offers greater type safety, a more PureScript-friendly interface, and has
-- | a `Generic` instance.
module Data.JSDate
  ( JSDate
  , LOCALE
  , readDate
  , isValid
  , fromDateTime
  , toDateTime
  , toDate
  , fromInstant
  , toInstant
  , jsdate
  , jsdateLocal
  , now
  , parse
  , getTime
  , getUTCDate
  , getUTCDay
  , getUTCFullYear
  , getUTCHours
  , getUTCMilliseconds
  , getUTCMinutes
  , getUTCMonth
  , getUTCSeconds
  , getDate
  , getDay
  , getFullYear
  , getHours
  , getMilliseconds
  , getMinutes
  , getMonth
  , getSeconds
  , getTimezoneOffset
  , toDateString
  , toISOString
  , toString
  , toTimeString
  , toUTCString
  ) where

import Prelude

import Control.Monad.Eff (kind Effect, Eff)
import Control.Monad.Eff.Exception (EXCEPTION)
import Control.Monad.Eff.Now (NOW)
import Data.Date as Date
import Data.DateTime (DateTime(..), Date)
import Data.DateTime as DateTime
import Data.DateTime.Instant (Instant)
import Data.DateTime.Instant as Instant
import Data.Enum (fromEnum)
import Data.Foreign (F, Foreign, unsafeReadTagged)
import Data.Foreign.Class (class Encode, class Decode)
import Data.Foreign.Generic as Fgn
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Generic.Rep (class Generic, Argument(..), Constructor(..))
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Data.Time as Time
import Data.Time.Duration (Milliseconds(..))

-- | The type of JavaScript `Date` objects.
foreign import data JSDate :: Type

instance eqJSDate :: Eq JSDate where
  eq a b = getTime a == getTime b

instance ordJSDate :: Ord JSDate where
  compare a b = getTime a `compare` getTime b

instance showJSDate :: Show JSDate where
  show a = "(fromTime " <> show (getTime a) <> ")"

instance genericJSDate :: Generic JSDate (Constructor "fromTime" (Argument Number)) where
  to (Constructor (Argument time)) = fromTime time
  from x = Constructor (Argument (getTime x))

instance encodeJSDate :: Encode JSDate where
  encode = Fgn.genericEncode Fgn.defaultOptions

instance decodeJSDate :: Decode JSDate where
  decode = Fgn.genericDecode Fgn.defaultOptions

-- | The effect type used when indicating the current machine's date/time locale
-- | is used in computing a value.
foreign import data LOCALE :: Effect

-- | Attempts to read a `Foreign` value as a `JSDate`.
readDate :: Foreign -> F JSDate
readDate = unsafeReadTagged "Date"

-- | Checks whether a date value is valid. When a date is invalid, the majority
-- | of the functions return `NaN`, `"Invalid Date"`, or throw an exception.
foreign import isValid :: JSDate -> Boolean

-- | Converts a `DateTime` value into a native JavaScript date object. The
-- | resulting date value is guaranteed to be valid.
fromDateTime :: DateTime -> JSDate
fromDateTime (DateTime d t) = jsdate
  { year: toNumber (fromEnum (Date.year d))
  , month: toNumber (fromEnum (Date.month d) - 1)
  , day: toNumber (fromEnum (Date.day d))
  , hour: toNumber (fromEnum (Time.hour t))
  , minute: toNumber (fromEnum (Time.minute t))
  , second: toNumber (fromEnum (Time.second t))
  , millisecond: toNumber (fromEnum (Time.millisecond t))
  }

-- | Attempts to construct a `DateTime` value for a `JSDate`. `Nothing` is
-- | returned only when the date value is an invalid date.
toDateTime :: JSDate -> Maybe DateTime
toDateTime = map Instant.toDateTime <$> toInstant

-- | Attempts to construct a `Date` value for a `JSDate`, ignoring any time
-- | component of the `JSDate`. `Nothing` is returned only when the date value
-- | is an invalid date.
toDate :: JSDate -> Maybe Date
toDate = map DateTime.date <$> toDateTime

-- | Creates a `JSDate` from an `Instant` value.
foreign import fromInstant :: Instant -> JSDate

-- | Attempts to construct an `Instant` for a `JSDate`. `Nothing` is returned
-- | only when the date value is an invalid date.
toInstant :: JSDate -> Maybe Instant
toInstant = Instant.instant <<< Milliseconds <=< toInstantImpl Just Nothing

foreign import toInstantImpl
  :: (forall a. a -> Maybe a)
  -> (forall a. Maybe a)
  -> JSDate
  -> Maybe Number

-- | Constructs a new `JSDate` from UTC component values. If any of the values
-- | are `NaN` the resulting date will be invalid.
foreign import jsdate
  :: { year :: Number
     , month :: Number
     , day :: Number
     , hour :: Number
     , minute :: Number
     , second :: Number
     , millisecond :: Number
     }
  -> JSDate

-- | Constructs a new `JSDate` from component values using the current machine's
-- | locale. If any of the values are `NaN` the resulting date will be invalid.
foreign import jsdateLocal
  :: forall eff
   . { year :: Number
     , month :: Number
     , day :: Number
     , hour :: Number
     , minute :: Number
     , second :: Number
     , millisecond :: Number
     }
  -> Eff (locale :: LOCALE | eff) JSDate

foreign import dateMethodEff :: forall eff a. Fn2 String JSDate (Eff eff a)
foreign import dateMethod :: forall a. Fn2 String JSDate a

-- | Attempts to parse a date from a string. The behaviour of this function is
-- | implementation specific until ES5, so may not always have the same
-- | behaviour for a given string. The RFC2822 and ISO8601 date string formats
-- | should parse consistently.
-- |
-- | The `LOCALE` effect is present here as if no time zone is specified in the
-- | string the current locale's time zone will be used instead.
foreign import parse
  :: forall eff. String -> Eff (locale :: LOCALE | eff) JSDate

-- | Gets a `JSDate` value for the date and time according to the current
-- | machine's clock.
-- |
-- | Unless a `JSDate` is required specifically, consider using the functions in
-- | `Control.Monad.Eff.Now` instead.
foreign import now :: forall eff. Eff (now :: NOW | eff) JSDate

-- | Returns the date as a number of milliseconds since 1970-01-01 00:00:00 UTC.
getTime :: JSDate -> Number
getTime dt = runFn2 dateMethod "getTime" dt

-- | Returns the day of the month for a date, according to UTC.
getUTCDate :: JSDate -> Number
getUTCDate dt = runFn2 dateMethod "getUTCDate" dt

-- | Returns the day of the week for a date, according to UTC.
getUTCDay :: JSDate -> Number
getUTCDay dt = runFn2 dateMethod "getUTCDay" dt

-- | Returns the year for a date, according to UTC.
getUTCFullYear :: JSDate -> Number
getUTCFullYear dt = runFn2 dateMethod "getUTCFullYear" dt

-- | Returns the hours for a date, according to UTC.
getUTCHours :: JSDate -> Number
getUTCHours dt = runFn2 dateMethod "getUTCHours" dt

-- | Returns the milliseconds for a date, according to UTC.
getUTCMilliseconds :: JSDate -> Number
getUTCMilliseconds dt = runFn2 dateMethod "getUTCMilliseconds" dt

-- | Returns the minutes for a date, according to UTC.
getUTCMinutes :: JSDate -> Number
getUTCMinutes dt = runFn2 dateMethod "getUTCMinutes" dt

-- | Returns the month for a date, according to UTC.
getUTCMonth :: JSDate -> Number
getUTCMonth dt = runFn2 dateMethod "getUTCMonth" dt

-- | Returns the seconds for a date, according to UTC.
getUTCSeconds :: JSDate -> Number
getUTCSeconds dt = runFn2 dateMethod "getUTCSeconds" dt

-- | Returns the day of the month for a date, according to the current
-- | machine's date/time locale.
getDate :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getDate dt = runFn2 dateMethodEff "getDate" dt

-- | Returns the day of the week for a date, according to the current
-- | machine's date/time locale.
getDay :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getDay dt = runFn2 dateMethodEff "getDay" dt

-- | Returns the year for a date, according to the current machine's date/time
-- | locale.
getFullYear :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getFullYear dt = runFn2 dateMethodEff "getFullYear" dt

-- | Returns the hour for a date, according to the current machine's date/time
-- | locale.
getHours :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getHours dt = runFn2 dateMethodEff "getHours" dt

-- | Returns the milliseconds for a date, according to the current machine's
-- | date/time locale.
getMilliseconds :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getMilliseconds dt = runFn2 dateMethodEff "getMilliseconds" dt

-- | Returns the minutes for a date, according to the current machine's
-- | date/time locale.
getMinutes :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getMinutes dt = runFn2 dateMethodEff "getMinutes" dt

-- | Returns the month for a date, according to the current machine's
-- | date/time locale.
getMonth :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getMonth dt = runFn2 dateMethodEff "getMonth" dt

-- | Returns the seconds for a date, according to the current machine's
-- | date/time locale.
getSeconds :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getSeconds dt = runFn2 dateMethodEff "getSeconds" dt

-- | Returns the time-zone offset for a date, according to the current machine's
-- | date/time locale.
getTimezoneOffset :: forall eff. JSDate -> Eff (locale :: LOCALE | eff) Number
getTimezoneOffset dt = runFn2 dateMethodEff "getTimezoneOffset" dt

-- | Returns the date portion of a date value as a human-readable string.
toDateString :: JSDate -> String
toDateString dt = runFn2 dateMethod "toDateString" dt

-- | Converts a date value to an ISO 8601 Extended format date string.
toISOString :: forall eff. JSDate -> Eff (exception :: EXCEPTION | eff) String
toISOString dt = runFn2 dateMethodEff "toISOString" dt

-- | Returns a string representing for a date value.
toString :: JSDate -> String
toString dt = runFn2 dateMethod "toString" dt

-- | Returns the time portion of a date value as a human-readable string.
toTimeString :: JSDate -> String
toTimeString dt = runFn2 dateMethod "toTimeString" dt

-- | Returns the date as a string using the UTC timezone.
toUTCString :: JSDate -> String
toUTCString dt = runFn2 dateMethod "toUTCString" dt

-- | Returns the date at a number of milliseconds since 1970-01-01 00:00:00 UTC.
foreign import fromTime :: Number -> JSDate
