module Main exposing (main)

import Html exposing (Html, button, div, text, input, li, ul, h3, h1, h2)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as JE
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Socket
import Room exposing(Room(..))
import Json.Decode as JD


--Program
main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


--Init
init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )

initializeSocket : Phoenix.Socket.Socket Msg
initializeSocket =
    Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug


socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"


--Model
type alias Model = {
  phxSocket: Phoenix.Socket.Socket Msg,
  roomCodeInput: String,
  playerNameInput: String,
  room: Room
}

initialModel : Model
initialModel =
  {
    phxSocket = initializeSocket,
    roomCodeInput = "",
    playerNameInput = "",
    room = None
  }

view : Model -> Html Msg
view model =
  div [] [
    h1 [] [text "DIY fall"],
    case model.room of
        None ->
          div [] [
            input [placeholder "Your name",
            onInput SetPlayerNameInput, value model.playerNameInput] [],
            input [placeholder "Game code",
            onInput SetRoomCodeInput, value model.roomCodeInput] [],
            button [onClick JoinRoom] [ text "Join Game" ]
          ]
        Lobby players ->
          div [] [text "Waiting for all players to join...",
                  div [] [button [onClick InitiateRound] [text "Start Game!"], playersView players]]
        Round players roundData ->
          div [] [
            roundDataView roundData,
            playersView players
          ]
  ]

roundDataView : Room.RoundData -> Html Msg
roundDataView roundData =
  case roundData of
    Room.SpyData -> div [] [text "You're the spy!"]
    Room.NonSpyData role location -> div [] [
      div [] [text "Location: ", text location, text " | Role: ", text role]


    ]
playersView : List String -> Html Msg
playersView players =
  div [] [
    h3 [] [text "Players Present"],
    ul [] (List.map (\p -> li [] [text p]) players)
  ]
--Update
type Msg =
    JoinRoom
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ProcessSocketData JE.Value
    | SetRoomCodeInput String
    | SetPlayerNameInput String
    | InitiateRound
    | RequestGameData
    | GameInSession

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    JoinRoom ->
      let
          ( phx, msg ) =
              joinChannel model
      in
      ( { model
          | phxSocket =
              phx
                |> Phoenix.Socket.on "update_game_data" ("games:"++model.roomCodeInput) (always RequestGameData)
                |> Phoenix.Socket.on "game_in_session" ("games:"++model.roomCodeInput) (always GameInSession)

        }
      , Cmd.map PhoenixMsg msg
      )
    PhoenixMsg msg ->
        let
          ( phxSocket, phxCmd ) =
              Phoenix.Socket.update msg model.phxSocket
        in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )
    SetRoomCodeInput input ->
      ({model | roomCodeInput = input}, Cmd.none)
    SetPlayerNameInput input ->
      ({model | playerNameInput = input}, Cmd.none)
    InitiateRound -> --TODO: definitely some extraction here
      let
        pmsg =
          initiateGame model

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.push pmsg model.phxSocket
      in
      ({model | phxSocket = phxSocket}, Cmd.map PhoenixMsg phxCmd)
    RequestGameData -> --TODO: definitely some extraction here
      let
        pmsg =
          requestGameData model

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.push pmsg model.phxSocket
      in
      ({model | phxSocket = phxSocket}, Cmd.map PhoenixMsg phxCmd)
    ProcessSocketData data ->
      case JD.decodeValue Room.decoder data of
        Ok room ->
          ({model | room = room}, Cmd.none)
        Err err ->
          let
            d = Debug.log "error" err
          in
          (model, Cmd.none) --TODO: handle errors!!
    GameInSession ->
      let
        d = Debug.log "READ ME:" "sorry, game in session!!!"
      in
      (model, Cmd.none)
--Subscriptions
subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg

-- -- Channels
initChannel : String -> String -> Phoenix.Channel.Channel Msg
initChannel channel playerName =
    Phoenix.Channel.init ("games:" ++ channel)
      |> Phoenix.Channel.withPayload (JE.string playerName)

joinChannel :
    Model
    -> ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
joinChannel   {phxSocket, roomCodeInput, playerNameInput} =
    phxSocket
        |> Phoenix.Socket.join (initChannel roomCodeInput playerNameInput)

requestGameData : Model -> Phoenix.Push.Push Msg
requestGameData model =
    Phoenix.Push.init "request_game_data" ("games:" ++ model.roomCodeInput)
    |> Phoenix.Push.onOk ProcessSocketData

initiateGame : Model -> Phoenix.Push.Push Msg
initiateGame model =
    Phoenix.Push.init "initiate" ("games:" ++ model.roomCodeInput)
    |> Phoenix.Push.onOk ProcessSocketData
