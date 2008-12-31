module Main where
    
import Control.Monad
import Control.Monad.MC
import Data.List
import Data.Map( Map )
import qualified Data.Map as Map
import System.Environment
import Text.Printf
    
-- | Data types for representing cards.  An Ace has 'number' equal to @1@.
-- Jack, Queen, and King have numbers @11@, @12@, and @13@, respectively.
data Suit = Club | Diamond  | Heart | Spade deriving (Eq, Show)
data Card = Card { number :: Int 
                 , suit   :: Suit
                 }
          deriving (Eq, Show)

-- | The number values of the aces and face cards.
ace, jack, queen, king :: Int
ace   = 1
jack  = 11
queen = 12
king  = 13

-- | A type for the various poker hands.
data Hand = HighCard  | Pair | TwoPair | ThreeOfAKind | Straight | Flush
          | FullHouse | FourOfAKind | StraightFlush 
          deriving (Eq, Show, Ord)

-- | Determine the hand corresponding to a list of five cards.
hand :: [Card] -> Hand
hand cs = 
    case matches of 
        [1,1,1,1,1] -> case undefined of
                           _ | isStraight && isFlush -> StraightFlush
                           _ | isFlush               -> Flush
                           _ | isStraight            -> Straight
                           _ | otherwise             -> HighCard
        [1,1,1,2]                                    -> Pair
        [1,2,2]                                      -> TwoPair
        [1,1,3]                                      -> ThreeOfAKind
        [2,3]                                        -> FullHouse
        [1,4]                                        -> FourOfAKind
  where
    (x:xs) = (sort . map number) cs
    (s:ss) = map suit cs
    
    isStraight | x == ace && xs == [ 10..king ] = True
               | otherwise                      = xs == [ x+1..x+4 ]

    isFlush = all (== s) ss

    matches = (sort . map length . group) (x:xs)

    
-- | Get a list of cards that make up a 52-card deck.
deck :: [Card]
deck = [ Card i s | i <- [ 1..13 ], s <- [ Club, Diamond, Heart, Spade ] ]

-- | Deal a five-card hand by choosing a random subset of the deck.
deal :: (MonadMC m) => m [Card]
deal = sampleSubset 5 52 deck

-- | A type for storing the frequencies of the various hands.
type HandCounts = Map Hand Int

-- | An empty frequency count.
emptyCounts :: HandCounts
emptyCounts = Map.empty

-- | Update the count of the hand corresponding to a list of five cards.
updateCounts :: HandCounts -> [Card] -> HandCounts
updateCounts counts cs = Map.insertWith' (+) (hand cs) 1 counts


main = do
    [reps] <- map read `fmap` getArgs
    main' reps

main' reps =
    let seed   = 0
        counts = repeatMCWith updateCounts emptyCounts reps deal
                 `evalMC` mt19937 seed in do
    printf "\n"
    printf "    Hand       Count    Probability     95%% Interval   \n"
    printf "-------------------------------------------------------\n"
    forM_ ((reverse . Map.toAscList) counts) $ \(h,c) ->
        let n     = fromIntegral reps :: Double
            p     = fromIntegral c / n 
            se    = sqrt (p * (1 - p) / n)
            delta = 1.959964 * se
            (l,u) = (p-delta, p+delta) in
        printf "%-13s %7d    %.6f   (%.6f,%.6f)\n" (show h) c p l u
    printf "\n"
