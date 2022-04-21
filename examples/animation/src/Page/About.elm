module Page.About exposing (view)

import Html as H
import Router exposing (Layout)


view : Layout msg
view =
    { title = Just "About"
    , attrs = []
    , main = [ H.section [] [ H.text "about page" ] ]
    }
