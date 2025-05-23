module Data.Either

import public Control.Function
import Data.List1

%default total

--------------------------------------------------------------------------------
-- Checking for a specific constructor

||| Extract the Left value, if possible
public export
getLeft : Either a b -> Maybe a
getLeft (Left a) = Just a
getLeft _ = Nothing

||| Extract the Right value, if possible
public export
getRight : Either a b -> Maybe b
getRight (Right b) = Just b
getRight _ = Nothing

||| True if the argument is Left, False otherwise
public export
isLeft : Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False

||| True if the argument is Right, False otherwise
public export
isRight : Either a b -> Bool
isRight (Left _)  = False
isRight (Right _) = True

||| Proof that an `Either` is actually a Right value
public export
data IsRight : Either a b -> Type where
  ItIsRight : IsRight (Right x)

export
Uninhabited (IsRight (Left x)) where
  uninhabited ItIsRight impossible

||| Returns the `r` value of an `Either l r` which is proved `Right`.
public export
fromRight : (e : Either l r) -> {auto 0 isRight : IsRight e} -> r
fromRight (Right r) = r
fromRight (Left _) impossible

||| Proof that an `Either` is actually a Left value
public export
data IsLeft : Either a b -> Type where
  ItIsLeft : IsLeft (Left x)

export
Uninhabited (IsLeft (Right x)) where
  uninhabited ItIsLeft impossible

||| Returns the `l` value of an `Either l r` which is proved `Left`.
public export
fromLeft : (e : Either l r) -> {auto 0 isLeft : IsLeft e} -> l
fromLeft (Right _) impossible
fromLeft (Left l) = l

--------------------------------------------------------------------------------
-- Grouping values

||| Compress the list of Lefts and Rights by accumulating
||| all of the lefts and rights into non-empty blocks.
export
compress : List (Either a b) -> List (Either (List1 a) (List1 b))
compress [] = []
compress (Left x :: abs) = compressLefts (singleton x) abs where
  compressLefts : List1 a -> List (Either a b) -> List (Either (List1 a) (List1 b))
  compressLefts acc (Left a :: abs) = compressLefts (cons a acc) abs
  compressLefts acc abs = Left (reverse acc) :: compress abs
compress (Right y :: abs) = compressRights (singleton y) abs where
  compressRights : List1 b -> List (Either a b) -> List (Either (List1 a) (List1 b))
  compressRights acc (Right b :: abs) = compressRights (cons b acc) abs
  compressRights acc abs = Right (reverse acc) :: compress abs

||| Decompress a compressed list. This is the left inverse of `compress` but not its
||| right inverse because nothing forces the input to be maximally compressed!
export
decompress : List (Either (List1 a) (List1 b)) -> List (Either a b)
decompress = concatMap $ \case
  Left  as => map Left  $ forget as
  Right bs => map Right $ forget bs

||| Keep the payloads of all Left constructors in a list of Eithers
public export
lefts : List (Either a b) -> List a
lefts []              = []
lefts (Left  l :: xs) = l :: lefts xs
lefts (Right _ :: xs) = lefts xs

||| Keep the payloads of all Right constructors in a list of Eithers
public export
rights : List (Either a b) -> List b
rights []              = []
rights (Left  _ :: xs) = rights xs
rights (Right r :: xs) = r :: rights xs

||| Split a list of Eithers into a list of the left elements and a list of the right elements
public export
partitionEithers : List (Either a b) -> (List a, List b)
partitionEithers l = (lefts l, rights l)

||| Remove a "useless" Either by collapsing the case distinction
public export
fromEither : Either a a -> a
fromEither (Left l)  = l
fromEither (Right r) = r

||| Right becomes left and left becomes right
public export
mirror : Either a b -> Either b a
mirror (Left  x) = Right x
mirror (Right x) = Left x

public export
Zippable (Either a) where
  zipWith f x y = [| f x y |]
  zipWith3 f x y z = [| f x y z |]

  unzipWith f (Left e) = (Left e, Left e)
  unzipWith f (Right xy) = let (x, y) = f xy in (Right x, Right y)

  unzipWith3 f (Left e) = (Left e, Left e, Left e)
  unzipWith3 f (Right xyz) = let (x, y, z) = f xyz in (Right x, Right y, Right z)

--------------------------------------------------------------------------------
-- Bifunctor

export
pushInto : c -> Either a b -> Either (c, a) (c, b)
pushInto c = bimap (\ a => (c, a)) (\ b => (c, b))
  -- ^ not using sections to keep it backwards compatible

--------------------------------------------------------------------------------
-- Conversions
--------------------------------------------------------------------------------

||| Convert a Maybe to an Either by using a default value in case of Nothing
||| @ e the default value
public export
maybeToEither : (def : Lazy e) -> Maybe a -> Either e a
maybeToEither def (Just j) = Right j
maybeToEither def Nothing  = Left  def

||| Convert an Either to a Maybe from Right injection
public export
eitherToMaybe : Either e a -> Maybe a
eitherToMaybe (Left _) = Nothing
eitherToMaybe (Right x) = Just x

export
eitherMapFusion : (f : _) -> (g : _) -> (p : _) -> (e : Either a b) -> either f g (map p e) = either f (g . p) e
eitherMapFusion f g p $ Left x  = Refl
eitherMapFusion f g p $ Right x = Refl

export
eitherBimapFusion : (f : _) -> (g : _) -> (p : _) -> (q : _) -> (e : _) -> either f g (bimap p q e) = either (f . p) (g . q) e
eitherBimapFusion f g p q $ Left z  = Refl
eitherBimapFusion f g p q $ Right z = Refl

-- Injectivity of constructors

||| Left is injective
export
Injective Left where
  injective Refl = Refl

||| Right is injective
export
Injective Right where
  injective Refl = Refl
