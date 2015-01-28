module Typography where

import String
import Html (Html, Attribute, span, div, text, toElement, fromElement, p)
import Html.Attributes (style, classList)
import Graphics.Element (widthOf)
import List as L
import Text
import Color
import Maybe
import Dict
import Dict (Dict)
import Utils
import Debug (log)

type Item = Box Int Html
          | Spring Int Int Int
          | Penalty Float Float Bool

textStyle = { typeface = [ "Georgia", "serif" ]
            , height   = Just 16
            , color    = Color.black
            , bold     = False
            , italic   = False
            , line     = Nothing
            }

typesetLines : Int -> String -> List Html
typesetLines lineWidth str =
    let txtLines = L.filter (not << String.isEmpty) << String.lines <| str
        paragraphPrefix str = "¶ " ++ str
        singleParText = String.join " " << L.map paragraphPrefix <| txtLines
        itemList = wordListToItems << String.words <| singleParText
    in fst <| L.foldl (justifyItems lineWidth) ([], []) itemList

-- TODO plaintext here will have to be replaced ...
strWidth : String -> Int
strWidth str = widthOf << Text.rightAligned << Text.style textStyle <| Text.fromString str

wordListToItems : List String -> List Item
wordListToItems words =
        let classes = classList [ ("maintext", True) ]
            toItem word = Box (strWidth word) (p [classes] [ text word ])
        in L.intersperse (Spring 4 2 2) <| L.map toItem words

itemWidth : Item -> Int
itemWidth i = case i of
    Box w _      -> w
    Spring w _ _ -> w
    otherwise    -> 0

itemHtml : Item -> Html
itemHtml item =
    let spanStyle : Int -> Attribute
        spanStyle w = style [ ("width", toString w ++ "px")
                            , ("display", "inline-block") ]
    in case item of
            Box w h   -> span [spanStyle w] [h]
            Spring w _ _ -> span [spanStyle w] []
            otherwise -> div [] []

itemListWidth : List Item -> Int
itemListWidth = L.sum << L.map itemWidth

isSpring : Item -> Bool
isSpring item = case item of
    Spring _ _ _ -> True
    otherwise    -> False

toSpring : Int -> Item
toSpring w = Spring w 0 0

justifyLine : Int -> List Item -> Html
justifyLine lineWidth is =
    let cleanList = L.filter (not << isSpring) is
        widthToAdd = lineWidth - itemListWidth cleanList
        numberSprings = L.length cleanList - 1
        baseSpringWidth = widthToAdd // numberSprings
        remainingWidth = rem widthToAdd numberSprings
        widthsToAdd = L.repeat remainingWidth (baseSpringWidth + 1) ++ L.repeat (numberSprings - remainingWidth) baseSpringWidth
        springs = L.map toSpring widthsToAdd
        items = Utils.interleave cleanList springs
    in p [] << L.map itemHtml <| items

-- TODO still dropping last line somehow...
-- TODO make this more efficient by having everything be an append, already had
-- this bit working but same drop last issue...
justifyItems : Int -> Item -> (List Html, List Item) -> (List Html, List Item)
justifyItems lineWidth item (hs, is) =
    let currentWidth = itemListWidth (is ++ [item])
    in if | currentWidth > lineWidth ->
                let nextLine = justifyLine lineWidth is
                    nextIs = if | isSpring item -> []
                                | otherwise -> [item]
                in (hs ++ [nextLine], nextIs)
          | otherwise -> (hs, is ++ [item])
