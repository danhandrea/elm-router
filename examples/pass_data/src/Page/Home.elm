module Page.Home exposing (view)

import Html as H exposing (Html)


view : List (Html msg)
view =
    [ H.h1 [] [ H.text "Home" ]
    , H.section [] [ H.text "home page" ]
    ]
