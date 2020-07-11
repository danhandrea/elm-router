module Page.About exposing (view)

import Html as H exposing (Html)


view : List (Html msg)
view =
    [ H.h1 [] [ H.text "About" ]
    , H.section [] [ H.text "about page" ]
    ]
