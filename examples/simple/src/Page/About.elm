module Page.About exposing (view)

import Html as H exposing (Html)


view : Html msg
view =
    H.div []
        [ H.h1 [] [ H.text "About" ]
        , H.section [] [ H.text "about page" ]
        ]
