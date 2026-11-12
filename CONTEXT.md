# CONTEXT

## UtilityNet client event batching

`QueueClientEvent` and `QueueCoalescedClientEvent` (`server/functions/utilityNet_batch.lua`) replace direct `TriggerClientEvent` calls for UtilityNet events that can fire in bursts: `EntityCreated`, `RequestDeletion`, `RefreshCoords`, `RefreshRotation`, `RefreshModel`.

- Events queued within `Config.UtilityNetBatch.interval` reach each player as one `Utility:Net:Batch` event. The client (`client/functions/utilityNet_batch.lua`) replays the entries in order with a local `TriggerEvent`, so every existing handler keeps its signature, including objectify's copies and the `callId` waiter in `UtilityNet.CreateEntity`.
- An entry is `{name, argsCount, ...args}`. `argsCount` is sent because args can be nil (a server created entity has no `callId`), and msgpack would otherwise lose the position of trailing nils.
- A broadcast shares one entry table across all queues, and its packed size is measured once.
- `QueueCoalescedClientEvent` keeps one slot per `name:coalesceKey` in each player queue, a later call overwrites the entry in place (last one wins). `SetEntityCoords` and `SetEntityRotation` coalesce by uNetId. The collapsed `RefreshCoords` keeps the `skipPositionUpdate` of the last call, so a real move followed by an attached-entity slice update inside the same window is not applied to the object.
- A batch is sent as a plain event, ordered with the other reliable events (state updates, RPCs). When a player's queue exceeds `Config.UtilityNetBatch.latentSize` bytes it is sent latent so a burst of entities cannot saturate the reliable channel. A latent batch can arrive after a plain event sent later.

## Interest management for entity create and delete

`EntityCreated` and `RequestDeletion` go only to the players in the entity slice or its 8 neighbours, plus the creating client, which waits for its own `EntityCreated` to resolve `UtilityNet.CreateEntity`.

- A model flagged with `UtilityNet.SetModelGlobalEvents` is sent to every player. Objectify flags every model whose script defines `OnRegister` or `OnUnregister`, since those run from these events regardless of distance.
- Clients can only turn the flag on, never off. The server API accepts `toggle = false`.
- A player entering a slice fetches its entities with `GetEntities`, so a missed create for a far entity is recovered when the player gets close.
