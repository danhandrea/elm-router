module Page.Home exposing (view)

import Html as H exposing (Html)


view : Html msg
view =
    H.div []
        [ H.h1 [] [ H.text "Home" ]
        , H.section [] [ H.text "home page" ]
        ]
