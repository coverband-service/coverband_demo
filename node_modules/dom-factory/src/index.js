require('core-js/modules/es6.array.find')

export { factory } from './factory'
export { handler } from './handler'

import { isElement } from './util/isElement'
import { isArray } from './util/isArray'
import { isFunction } from './util/isFunction'
import { toKebabCase } from './util/toKebabCase'
import { assign } from './util/assign'
import { transform } from './util/transform'

export const util = {
  assign,
  isArray,
  isElement,
  isFunction,
  toKebabCase,
  transform
}