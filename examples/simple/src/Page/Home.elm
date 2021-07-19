module Page.Home exposing (view)

import Html as H
import Router exposing (Layout)


view : Layout msg
view =
    { title = Nothing
    , attrs = []
    , main = [ H.section [] [ H.text "home page" ] ]
    }
