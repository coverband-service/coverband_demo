# dom-factory

[![npm version](https://badge.fury.io/js/dom-factory.svg)](https://badge.fury.io/js/dom-factory)

The DOM factory provides a convenient API (inspired by Polymer) to enhance HTML elements with custom behavior, using plain JavaScript objects with advanced features like property change observers, property reflection to attributes on HTML elements and simplify mundane tasks like adding and removing event listeners.

## Compatibility

> Supports the last two versions of every major browser.

- Chrome
- Safari
- Firefox
- IE 11/Edge
- Opera
- Mobile Safari
- Chrome on Android

## Installation

```bash
npm install dom-factory
```

## Usage

The DOM factory library exports to AMD, CommonJS and global.

### Global

```html
<script src="node_modules/dom-factory/dist/dom-factory.js"></script>
<script>
  var handler = domFactory.handler
</script>
```

### CommonJS

```js
var handler = require('dom-factory').handler
```

### ES6

```js
import { handler } from 'dom-factory'
```

### Components

The following ES6 example, illustrates a component definition for an enhanced button using properties as a public API, property reflection to attributes, property change observers and event listeners.

#### Component definition

A component definition is nothing more than a simple object factory (a function that creates an object) which accepts a `HTMLElement` node as it's argument.

```js
/**
 * A component definition
 * @return {Object}
 */
const buttonComponent = () => ({

  /**
   * Properties part of the component's public API.
   * @type {Object}
   */
  properties: {

    /**
     * Maps to [data-a-property="value"] attribute
     * Also sets a default property value 
     * and updates the attribute on the HTMLElement
     * @type {Object}
     */
    aProperty: {
      reflectToAttribute: true,
      value: 'value for aProperty'
    },

    /**
     * Maps to [data-b-property] attribute
     * It removes the attribute when the property value is `false`
     * @type {Object}
     */
    bProperty: {
      reflectToAttribute: true,
      type: Boolean
    },

    /**
     * Maps to [data-c-property] attribute
     * It casts the value to a Number
     * Sets the initial value to 0
     * @type {Object}
     */
    cProperty: {
      reflectToAttribute: true,
      type: Number,
      value: 0
    }
  },

  /**
   * Property change observers.
   * @type {Array}
   */
  observers: [
    '_onPropertyChanged(aProperty, bProperty)'
  ],

  /**
   * Event listeners.
   * @type {Array}
   */
  listeners: [
    '_onClick(click)'
  ],

  /**
   * Property change observer handler
   * @param  {?}      newValue The new property value
   * @param  {?}      oldValue The old property value
   * @param  {String} propName The property name
   */
  _onPropertyChanged (newValue, oldValue, propName) {
    switch (propName) {
      case 'aProperty':
        console.log('aProperty has changed', newValue, oldValue)
        break
      case 'bProperty':
        console.log('bProperty has changed', newValue, oldValue)
        break
    }

    // access from context, with the new values
    console.log(this.aProperty, this.bProperty)
  },

  /**
   * Click event listener
   * @param  {MouseEvent} event The Mouse Event
   */
  _onClick (event) {
    event.preventDefault()
    console.log('The button was clicked!')
  }
})
```

#### Register the component

```js
handler.register('my-button', buttonComponent)
```

#### Initializing

When calling the `autoInit()` method, the component handler attempts to self-initialize all registered components which match the component CSS class. The CSS class is computed automatically from the component ID which was provided at registration, prefixed with `js-`.

In this example, since we registered the `buttonComponent` with a component ID of `my-button`, the handler will try to initialize all the HTML elements which have the `js-my-button` CSS class.

```html
<button class="js-my-button">Press me</button>
```

```js
// Initialize all components on window.DOMContentLoaded and window.load events.
handler.autoInit()
```

You can also initialize components manually.

```js
// Initialize all components immediately.
handler.upgradeAll()

// Initialize all components on a single element.
var myButtonNode = document.querySelector('.js-my-button')
handler.upgradeElement(myButtonNode)

// Initialize a single component on a single element.
handler.upgradeElement(myButtonNode, 'my-button')

// Upgrade all elements matching a registered component ID.
handler.upgrade('my-button')
```

#### Downgrade

Sometimes we need component lifecycle control when integrating with other libraries (Vue.js, Angular, etc).

```js
var myButtonNode = document.querySelector('.js-my-button')
handler.downgradeElement(myButtonNode)
```

#### Interact with the component API

When the handler initializes a component on a HTML element, a reference to the created component is stored as a property on the HTML element, matching the `camelCase` version of the component ID.

```js
var buttonNode = document.querySelector('button')
var button = buttonNode.myButton
```

We can use this reference to interact with the component's API.

```js
console.log(button.aProperty)
// => 'value for aProperty'
```

#### Property reflection to attribute

```js
button.aProperty = 'something else'
button.bProperty = true
button.cProperty = 5
```

When using the `reflectToAttribute: true` property option, the property reflects a string representation of it's value to the corresponding `data-*` attribute on the HTML element using the `dataset` API, which means you can use the HTML element attribute to configure the property value.

#### Casting values

Because component properties using `reflectToAttribute: true` are using the dataset API, all values are strings by default, but you can cast them to `Boolean` or `Number`.

> Boolean

When using a `Boolean` property type and assigning a property value of `true`, the attribute will be created on the HTML element with an empty value and when assigning a property value of `false`, the attribute will be removed from the DOM. 

For example, an attribute with an empty value called `[data-my-boolean-attribute]` will map to `button.myBooleanAttribute`.

```html
<button data-my-boolean-attribute class="js-my-button">
  Press me
</button>
```

```js
`console.log(button.myBooleanAttribute) // => true`
```

> Number

Cast the component property value to a `Number` by adding `type: Number` to the property definition. It returns `NaN` when the value is not a valid number.

```js
button.cProperty = '50'
console.log(button.cProperty) // => 50

button.cProperty = 'abc'
console.log(button.cProperty) // => NaN
```

```html
<button class="js-my-button" 
  data-a-property="something else" 
  data-b-property
  data-c-property="13">
  Press me
</button>
```

```js
console.log(button.aProperty) // => 'something else'
console.log(button.bProperty) // => true
console.log(button.cProperty) // => 13
```

#### Destroy

Calling the `destroy` method on the component reference, removes observers and event listeners. Useful before removing the HTML element from the DOM, for example when using libraries like Vue.js or Angular2 where you need to hook into the application lifecycle.

```js
button.destroy()
```