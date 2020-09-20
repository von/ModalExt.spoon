# [docs](index.md) » ModalExt
---

Kudos for cheatsheet: https://github.com/ashfinal/awesome-hammerspoon

## API Overview
* Variables - Configurable values
 * [defaults](#defaults)
 * [modifiers](#modifiers)
* Functions - API calls offered directly by the extension
 * [debug](#debug)
 * [init](#init)
 * [start](#start)
 * [stop](#stop)
* Constructors - API calls which return an object, typically one that offers API methods
 * [new](#new)
* Methods - API calls which can only be made on an object returned by a constructor
 * [hideCheatsheet](#hideCheatsheet)
 * [showCheatsheet](#showCheatsheet)

## API Documentation

### Variables

| [defaults](#defaults)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt.defaults`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | Dictionary of defaults:                                                                     |

| [modifiers](#modifiers)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt.modifiers`                                                                    |
| **Type**                                    | Variable                                                                     |
| **Description**                             | Dictionary with keys that serve as aliases for all the various modifer key                                                                     |

### Functions

| [debug](#debug)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt:debug(enable)`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Enable or disable debugging                                                                     |
| **Parameters**                              | <ul><li>enable - Boolean indicating whether debugging should be on</li></ul> |
| **Returns**                                 | <ul><li>Nothing</li></ul>          |

| [init](#init)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt:init()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Initializes a ModalExt                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>ModalExt object</li></ul>          |

| [start](#start)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt:start()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Start background activity. Currently does nothing.                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>ModalExt object</li></ul>          |

| [stop](#stop)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt:stop()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Stop background activity.                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>ModalExt object</li></ul>          |

### Constructors

| [new](#new)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt:new()`                                                                    |
| **Type**                                    | Constructor                                                                     |
| **Description**                             | Create a new modal hotkey using bindings from the given table. Table elements are                                                                     |
| **Parameters**                              | <ul><li>* modalConfig: Table with configuration</li></ul> |
| **Returns**                                 | <ul><li>* hs.hotkey.modal instance</li></ul>          |

### Methods

| [hideCheatsheet](#hideCheatsheet)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt:hideCheatsheet()`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Hide the cheatsheet.                                                                     |
| **Parameters**                              | <ul><li>* None</li></ul> |
| **Returns**                                 | <ul><li>* Nothing</li></ul>          |

| [showCheatsheet](#showCheatsheet)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `ModalExt:showCheatsheet()`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Show a cheatsheet with available hotkeys for the current modal.                                                                     |
| **Parameters**                              | <ul><li>* defaults: copy of ModalExt.defaults</li></ul> |
| **Returns**                                 | <ul><li>* Nothing</li></ul>          |

