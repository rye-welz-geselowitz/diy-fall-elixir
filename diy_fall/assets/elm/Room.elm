module Room exposing (Room(..), decoder, RoundData(..))

import Json.Decode as JD exposing (Decoder)


type Room =
  None
  | Lobby (List PlayerName)
  | Round (List PlayerName) RoundData

type RoundData =
  NonSpyData Role Location | SpyData

type alias Role = String
type alias Location = String

decoder : Decoder Room
decoder =
  JD.map3 (\players data isRoundInSession ->
     if isRoundInSession then
      case data of
        Nothing ->
          (Round players SpyData)
        Just roundData ->
          (Round players roundData)
      else
        Lobby players)

    (JD.at ["players"] (JD.list JD.string))
    (JD.at ["round"] (JD.nullable roundDataDecoder) )
    (JD.at ["is_round_in_session"] (JD.bool) )

roundDataDecoder : Decoder RoundData
roundDataDecoder =
  JD.map2 (\role location -> NonSpyData role location)
  (JD.at ["role"] JD.string)
  (JD.at["location_name"] JD.string)

-- goToLobby : Room -> Room
-- goToLobby room =
--   Lobby


type alias PlayerName = String
