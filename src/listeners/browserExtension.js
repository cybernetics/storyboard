import { merge, addDefaults, set as timmSet } from 'timm';
import filters from '../gral/filters';
import ifExtension from './helpers/interfaceExtension';

const DEFAULT_CONFIG = {};

// -----------------------------------------
// Listener
// -----------------------------------------
function BrowserExtensionListener(config) {
  this.type = 'BROWSER_EXTENSION';
  this.config = config;
}

BrowserExtensionListener.prototype.init = function() {
  ifExtension.rx(this.extensionRxMsg);
}

// To the extension
BrowserExtensionListener.prototype.process = function(record) {
  ifExtension.tx({ type: 'RECORDS', data: [record] });
};

// From the extension
BrowserExtensionListener.prototype.extensionRxMsg = function(msg) {
  const { type, data } = msg;
  switch (type) {
    case 'GET_LOCAL_CLIENT_FILTER':
    case 'SET_LOCAL_CLIENT_FILTER':
      if (type === 'SET_LOCAL_CLIENT_FILTER') filters.config(data);
      ifExtension.tx({
        type: 'LOCAL_CLIENT_FILTER',
        result: 'SUCCESS',
        data: { filter: filters.getConfig() },
      });
      break;
    default:
      break;
  }
};

// -----------------------------------------
// Helpers
// -----------------------------------------
const outputLog = function(text, level, fLongDelay) {
  const args = k.IS_BROWSER ?
    ansiColors.getBrowserConsoleArgs(text) :
    [text];
  if (fLongDelay) console.log('          ...');
  const output = (level >= 50 && level <= 60) ? 'error' : 'log';
  console[output].apply(console, args);
};

// -----------------------------------------
// API
// -----------------------------------------
const create = config => new BrowserExtensionListener(addDefaults(config, DEFAULT_CONFIG));

export default create;