module Typography where

import String
import Html (Html, Attribute, span, div, text, toElement, fromElement, p)
import Html.Attributes (style)
import Graphics.Element (widthOf)
import List as L
import Text (plainText)
import Maybe
import Dict
import Dict (Dict)
import Utils
import Debug (log)

type Item = Box Int Html
          | Spring Int Int Int
          | Penalty Float Float Bool

typesetLines : Int -> String -> List Html
typesetLines lineWidth str =
    let txtLines = L.filter (not << String.isEmpty) << String.lines <| str
        paragraphPrefix str = "¶ " ++ str
        singleParText = String.join " " << L.map paragraphPrefix <| txtLines
        itemList = wordListToItems << String.words <| singleParText
    in fst <| L.foldl (justifyItems lineWidth) ([], []) itemList

-- TODO plaintext here will have to be replaced ...
strWidth : String -> Int
strWidth str = widthOf <| plainText str

wordListToItems : List String -> List Item
wordListToItems words =
        let toItem word = Box (strWidth word) (text word)
        in L.intersperse (Spring 5 2 2) <| L.map toItem words

itemWidth : Item -> Int
itemWidth i = case i of
    Box w _      -> w
    Spring w _ _ -> w
    otherwise    -> 0

itemHtml : Item -> Html
itemHtml i = case i of
    Box _ h   -> h
    Spring _ _ _ ->
        let spanStyle : Attribute
            spanStyle = style [("width", "5px")
                              , ("display", "inline-block")]
        in span [spanStyle] []
    otherwise -> div [] []

itemListWidth : List Item -> Int
itemListWidth = L.sum << L.map itemWidth

isSpring : Item -> Bool
isSpring item = case item of
    Spring _ _ _ -> True
    otherwise    -> False

justifyLine : List Item -> Html
justifyLine = p [] << L.map itemHtml

justifyItems : Int -> Item -> (List Html, List Item) -> (List Html, List Item)
justifyItems lineWidth item (hs, is) =
    let currentWidth = itemListWidth (is ++ [item])
    in if | currentWidth > lineWidth ->
                let nextLine = justifyLine is
                    nextIs = if | isSpring item -> []
                                | otherwise -> [item]
                in (hs ++ [nextLine], nextIs)
          | otherwise -> (hs, is ++ [item])
