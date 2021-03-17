module Page.NotFound exposing (Model, init, view)

import Html as H exposing (Html)
import Url exposing (Url)


type alias Model =
    Url


init : Url -> Model
init url =
    url


view : Model -> Html msg
view url =
    H.div [] [ H.text <| "Page " ++ Url.toString url ++ ", not found!" ]
