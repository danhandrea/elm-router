module Page.NotFound exposing (view)

import Html as H
import Router exposing (Layout)
import Url exposing (Url)


view : Url -> Layout msg
view url =
    { title = Just "Not found!"
    , attrs = []
    , main =
        [ H.text <| Url.toString url ++ " not found!"
        ]
    }
