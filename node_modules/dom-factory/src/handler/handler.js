import { factory } from '../factory'

const toCamelCase = (str) => str.replace(/(\-[a-z])/g, ($1) => $1.toUpperCase().replace('-', ''))

// The property name used to store the component config on a component reference
const CONFIG_PROPERTY = '__domFactoryConfig'

/**
 * Component handler
 * @type {Object}
 */
export const handler = {

  autoInit () {
    ['DOMContentLoaded', 'load'].forEach(function (e) {
      window.addEventListener(e, () => handler.upgradeAll())
    })
  },

  // Registered components
  _registered: [],

  // Created component references
  _created: [],

  /**
   * Register a component.
   * @param  {String} id      A unique component ID.
   * @param  {Object} factory The component definition object.
   */
  register (id, factory) {
    const callbacks = []
    const cssClass = `js-${ id }`

    if (!this.findRegistered(id)) {
      this._registered.push({
        id,
        cssClass,
        callbacks,
        factory
      })
    }
  },

  /**
   * Register a callback to be called on component upgrade.
   * @param  {String}   id       The component ID.
   * @param  {Function} callback The callback function.
   */
  registerUpgradedCallback (id, callback) {
    const config = this.findRegistered(id)
    if (config) {
      config.callbacks.push(callback)
    }
  },

  /**
   * Get a registered component.
   * @param  {String} id The component ID.
   * @return {Object}    A configuration object.
   */
  findRegistered (id) {
    return this._registered.find(config => config.id === id)
  },

  /**
   * Get a created component reference for an element.
   * @param  {HTMLElement} element
   * @return {Object}
   */
  findCreated (element) {
    return this._created.filter(ref => ref.element === element)
  },

  /**
   * Upgrade an element with a single component type or all of the registered components.
   * @param  {HTMLElement}  element The element to upgrade.
   * @param  {String}       id      The component ID (optional).
   */
  upgradeElement (element, id) {
    if (id === undefined) {
      this._registered.forEach(config => {
        if (element.classList.contains(config.cssClass)) {
          this.upgradeElement(element, config.id)
        }
      })
      return
    }

    let upgraded = element.getAttribute('data-domfactory-upgraded')
    const config = this.findRegistered(id)

    if (config && (upgraded === null || upgraded.indexOf(id) === -1)) {
      upgraded = upgraded === null ? [] : upgraded.split(',')
      upgraded.push(id)

      let component
      try {
        component = factory(config.factory(element), element)
      }
      catch (e) {
        console.error(id, e.message, e.stack)
      }

      if (component) {
        element.setAttribute('data-domfactory-upgraded', upgraded.join(','))

        const instanceConfig = Object.assign({}, config)
        delete instanceConfig.factory
        component[CONFIG_PROPERTY] = instanceConfig

        this._created.push(component)

        Object.defineProperty(element, toCamelCase(id), {
          configurable: true,
          writable: false,
          value: component
        })

        config.callbacks.forEach(cb => cb(element))
        component.fire('domfactory-component-upgraded')
      }
    }
    else if (config) {
      let component = element[toCamelCase(id)]
      if (typeof component._reset === 'function') {
        component._reset()
      }
    }
  },

  /**
   * Upgrade all elements matching a registered component ID.
   * @param  {String} id       The component ID.
   */
  upgrade (id) {
    if (id === undefined) {
      this.upgradeAll()
    }
    else {
      const config = this.findRegistered(id)
      if (config) {
        const elements = [...document.querySelectorAll('.' + config.cssClass)]
        elements.forEach(element => this.upgradeElement(element, id)) 
      }
    }
  },

  /**
   * Upgrade all elements matching the registered components.
   */
  upgradeAll () {
    this._registered.forEach(config => this.upgrade(config.id))
  },

  /**
   * Downgrade a component reference.
   * @param  {Object} component
   */
  downgradeComponent (component) {
    component.destroy()
    const index = this._created.indexOf(component)
    this._created.splice(index, 1)
    
    const upgrades = component.element.getAttribute('data-domfactory-upgraded').split(',')
    const upgradeIndex = upgrades.indexOf(component[CONFIG_PROPERTY].id)
    upgrades.splice(upgradeIndex, 1)
    component.element.setAttribute('data-domfactory-upgraded', upgrades.join(','))
    component.fire('domfactory-component-downgraded')
  },

  /**
   * Downgrade an element.
   * @param  {HTMLElement} element
   */
  downgradeElement (element) {
    this.findCreated(element).forEach(this.downgradeComponent, this)
  },

  /**
   * Downgrade all the created components.
   */
  downgradeAll () {
    this._created.forEach(this.downgradeComponent, this)
  },

  /**
   * Downgrade a single element, a NodeList or an array of elements
   * @param  {Node|Array<Node>|NodeList} node
   */
  downgrade (node) {
    if (node instanceof Array || node instanceof NodeList) {
      const nodes = node instanceof NodeList ? [...node] : node
      nodes.forEach(element => this.downgradeElement(element))
    }
    else if (node instanceof Node) {
      this.downgradeElement(node)
    }
  }
}