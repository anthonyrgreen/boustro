module UI where

import Time (Time, every, second, millisecond, timestamp)
import Maybe as M
import Html (Html, toElement)
import Graphics.Element (Element, container, middle)
import List as L
import Touch
import Signal as S
import Signal ((<~), (~), Signal)
import Window
import Utils

type alias WindowDimensions = (Int, Int)

type alias ViewDimensions = { fullWidth    : Int
                            , fullHeight   : Int
                            , textWidth    : Int
                            , textHeight   : Int
                            , linesPerPage : Int
                            }

type alias ViewState = { pageWordCount  : Int
                       , view           : Element
                       , viewDimensions : ViewDimensions
                       }

scene : Html -> ViewDimensions -> Element
scene page viewDimensions =
    let renderTextView = toElement viewDimensions.textWidth
                                   viewDimensions.textHeight
        fullContainer = container viewDimensions.fullWidth
                                  viewDimensions.fullHeight
                                  middle
    in  fullContainer <| renderTextView page


lineHeight = 19 -- TODO this should depend on the styles in Typography

viewHelper : WindowDimensions -> ViewDimensions
viewHelper (w, h) = let textHeight = (h // lineHeight - 6) * lineHeight
                    in { fullWidth = w
                       , fullHeight = h
                       , textWidth = min (w - 40) 650
                       , textHeight = textHeight
                       , linesPerPage = textHeight // lineHeight
                       }

initialSetupSignal : Signal ()
initialSetupSignal = S.map Utils.toUnit << S.dropRepeats
                                        << S.foldp (\x p -> 1) 0
                                        <| every (10 * millisecond)

currentWindowDimensions : Signal WindowDimensions
currentWindowDimensions =
    let cues = S.mergeMany [ S.map Utils.toUnit Window.dimensions
                           , S.map Utils.toUnit initialSetupSignal
                           ]
    in S.sampleOn cues <| Window.dimensions

currentViewDimensions : Signal ViewDimensions
currentViewDimensions = S.map viewHelper currentWindowDimensions

type SwipeDir = Next | Prev | NoSwipe
type UserInput = Swipe SwipeDir
               | SetText String

type alias Tap = { x : Int, y : Int }

swipe : Signal SwipeDir
swipe = let untappedValue : (Time, Tap, Bool)
            untappedValue = (0, { x = -1, y = -1 }, False)
            doubleTap = S.map (\(x,y,z) -> z) <| S.foldp isDoubleTap untappedValue
                                              <| timestamp Touch.taps
            toSwipeDir tap viewDims =
                if | tap.x < (viewDims.fullWidth // 2 - 10) -> Prev
                   | tap.x > (viewDims.fullWidth // 2 + 10) -> Next
                   | otherwise -> NoSwipe
            currentSwipeDir = S.map2 toSwipeDir Touch.taps currentViewDimensions
        in  S.sampleOn (Utils.onFalseTrueTransition doubleTap) currentSwipeDir

isDoubleTap : (Time, Tap) -> (Time, Tap, Bool) -> (Time, Tap, Bool)
isDoubleTap (newTapTime, newTap) (oldTapTime, oldTap, wasDoubleTap) =
    let doubleTapMargin : Int
        doubleTapMargin = 80
        maxDoubleTapInteval : Time
        maxDoubleTapInteval = 0.5 * second
    in if | wasDoubleTap -> (newTapTime, newTap, False)
          | newTapTime - oldTapTime < maxDoubleTapInteval &&
              abs (newTap.x - oldTap.x) < doubleTapMargin &&
              abs (newTap.y - oldTap.y) < doubleTapMargin ->
                            (newTapTime, newTap, True)
          | otherwise    -> (newTapTime, newTap, False)
