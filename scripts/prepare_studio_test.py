"""Compose an isolated Studio test runner without test hooks in production source."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
def long_string(text):
    eq = "===="
    assert "]" + eq + "]" not in text
    return "[" + eq + "[" + text + "]" + eq + "]"

client = (ROOT / "tests/multiplayer.client.luau").read_text(encoding="utf-8")
server = (ROOT / "tests/multiplayer.server.luau").read_text(encoding="utf-8")
runner = '''-- run-in-roblox's plugin also loads in test DataModels. Only the edit instance may launch tests.
if not game:GetService("StudioTestService").EditModeActive then
    while true do task.wait(60) end
end
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local bridge=Instance.new("RemoteEvent")
bridge.Name="RuntimeTestBridge";bridge.Parent=ReplicatedStorage
local server=Instance.new("ModuleScript")
server.Name="RuntimeTests";server.Source=SERVER_SOURCE;server.Parent=ServerScriptService.Server
local client=Instance.new("LocalScript")
client.Name="RuntimeTests";client.Source=CLIENT_SOURCE;client.Parent=StarterPlayer.StarterPlayerScripts
ServerScriptService.Server.Bootstrap.Source=[[local Game=require(script.Parent.Game)
local session=Game.new():start()
require(script.Parent.RuntimeTests)(session)]]
local result=game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,{suite="Wisteria",visual=__VISUAL_ARG__,visualSagiri=__SAGIRI_ARG__,visualCombat=__COMBAT_ARG__,virtualInput=__INPUT_ARG__})
print("RUNTIME_JSON "..game:GetService("HttpService"):JSONEncode(result))
assert(result and result.failures==0,"Multiplayer tests failed")
'''.replace("SERVER_SOURCE", long_string(server)).replace("CLIENT_SOURCE", long_string(client)).replace("__VISUAL_ARG__", "true" if "--visual" in sys.argv or "--visual-sagiri" in sys.argv else "false").replace("__SAGIRI_ARG__", "true" if "--visual-sagiri" in sys.argv else "false").replace("__COMBAT_ARG__", "true" if "--visual-combat" in sys.argv else "false").replace("__INPUT_ARG__", "true" if "--virtual-input" in sys.argv else "false")
(ROOT / "build").mkdir(exist_ok=True)
(ROOT / "build/run-multiplayer.luau").write_text(runner,encoding="utf-8")
print("Prepared build/run-multiplayer.luau")
