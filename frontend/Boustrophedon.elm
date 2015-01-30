import List as L
import Html (toElement)
import Graphics.Element (Element, container, middle)
import Signal as S
import Signal ((<~), (~), Signal)
import UI (..)
import Server
import Model (..)
import Utils
import Debug (log)
import Typography

stringToState : String -> AppState
stringToState str = { fullText  = Typography.strToWordArray str
                    , wordIndex = 0
                    }

nextState : UserInput -> AppState -> AppState
nextState userInput pState =
    case userInput of
        SetText str     -> stringToState str
        Swipe Next      -> { pState | wordIndex <- 0 }
        Swipe Prev      -> { pState | wordIndex <- 0 }
        Swipe NoSwipe   -> pState

emptyState = stringToState Server.defaultText

appState : Signal AppState
appState = S.foldp nextState emptyState userInput

userInput : Signal UserInput
userInput = S.mergeMany [ S.map SetText Server.textContent
                        , S.map Swipe swipe
                        ]

scene : AppState -> ViewDimensions -> Element
scene state viewDimensions =
    let renderTextView = toElement viewDimensions.textWidth
                                   viewDimensions.textHeight
        fullContainer = container viewDimensions.fullContainerWidth
                                  viewDimensions.fullContainerHeight
                                  middle
        (page, _) = Typography.typesetPage state viewDimensions
    in  fullContainer <| renderTextView page

main : Signal Element
main = scene <~ appState
              ~ currentViewDimensions
