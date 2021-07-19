module Page.Contact exposing (Model, Msg, init, subscriptions, update, view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Router exposing (Layout)
import Time



-- MODEL


type alias Model =
    { name : String
    , email : String
    , ticks : Int
    }



-- MSG


type Msg
    = Name String
    | Email String
    | Tick Time.Posix



-- INIT


init : String -> String -> ( Model, Cmd Msg )
init name email =
    ( Model name email 0, Cmd.none )



-- update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Name name ->
            ( { model | name = name }, Cmd.none )

        Email email ->
            ( { model | email = email }, Cmd.none )

        Tick _ ->
            ( { model | ticks = model.ticks + 1 }, Cmd.none )



-- VIEW


view : Model -> Layout Msg
view { name, email, ticks } =
    { title = Just "Contact"
    , attrs = []
    , main =
        [ H.section []
            [ H.input
                [ A.type_ "text", A.value name, E.onInput Name ]
                []
            , H.input
                [ A.type_ "email", A.value email, E.onInput Email ]
                []
            , H.label [] [ H.text <| "ticks : " ++ String.fromInt ticks ]
            ]
        ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick
