'use strict';

var _interopRequireDefault = function (obj) { return obj && obj.__esModule ? obj : { 'default': obj }; };

var _cblang = require('../lib/index.js');

var _cblang2 = _interopRequireDefault(_cblang);

var _parse = require('../src/parser.js');

var _assert = require('chai');

describe('Filters', function () {
    it('can be used without context', function () {
        var input = 'shane';
        var output = _parse.parse(input);
        _assert.assert.equal(output.length, 1);
        _assert.assert.equal(output[0].type, 'buffer');
        _assert.assert.equal(output[0].value, 'shane');
    });
    it('1 filter', function () {
        var input = '{shane|upper}';
        var output = _parse.parse(input);
        _assert.assert.equal(output.length, 1);
        _assert.assert.equal(output[0].type, 'reference');
        _assert.assert.equal(output[0].identifier.type, 'key');
        _assert.assert.equal(output[0].identifier.value, 'shane');
        _assert.assert.equal(output[0].filters.length, 1);
        _assert.assert.equal(output[0].filters[0], 'upper');
    });
    it('1 modifier', function () {
        var input = '{shane|lodash:upper}';
        var output = _parse.parse(input);
        _assert.assert.equal(output.length, 1);
        _assert.assert.equal(output[0].type, 'reference');
        _assert.assert.equal(output[0].identifier.type, 'key');
        _assert.assert.equal(output[0].identifier.value, 'shane');
        _assert.assert.equal(output[0].modifiers.length, 1);
        _assert.assert.equal(output[0].modifiers[0].namespace, 'lodash');
        _assert.assert.equal(output[0].modifiers[0].value, 'upper');
    });
    it('2 modifiers', function () {
        var input = '{shane|lodash:upper|moment:kill}';
        var output = _parse.parse(input);
        _assert.assert.equal(output.length, 1);
        _assert.assert.equal(output[0].type, 'reference');
        _assert.assert.equal(output[0].identifier.type, 'key');
        _assert.assert.equal(output[0].identifier.value, 'shane');
        _assert.assert.equal(output[0].modifiers.length, 2);
        _assert.assert.equal(output[0].modifiers[0].namespace, 'lodash');
        _assert.assert.equal(output[0].modifiers[1].namespace, 'moment');
    });
    it('2 modifiers + filter', function () {
        var input = '{shane|lodash:upper|moment:kill|truncate}';
        var output = _parse.parse(input);
        _assert.assert.equal(output.length, 1);
        _assert.assert.equal(output[0].type, 'reference');
        _assert.assert.equal(output[0].identifier.type, 'key');
        _assert.assert.equal(output[0].identifier.value, 'shane');
        _assert.assert.equal(output[0].modifiers.length, 2);
        _assert.assert.equal(output[0].modifiers[0].namespace, 'lodash');
        _assert.assert.equal(output[0].modifiers[1].namespace, 'moment');
        _assert.assert.equal(output[0].filters[0], 'truncate');
    });
    it.only('filter first + 2 modifiers', function () {
        var input = '{shane|upper|lodash:upper|moment:kill}';
        var output = _parse.parse(input);
        _assert.assert.equal(output.length, 1);
        _assert.assert.equal(output[0].type, 'reference');
        _assert.assert.equal(output[0].identifier.type, 'key');
        _assert.assert.equal(output[0].identifier.value, 'shane');
        _assert.assert.equal(output[0].modifiers.length, 2);
        _assert.assert.equal(output[0].modifiers[0].namespace, 'lodash');
        _assert.assert.equal(output[0].modifiers[1].namespace, 'moment');
        _assert.assert.equal(output[0].filters[0], 'upper');
    });
    it('2 filters', function () {
        var input = '{shane|upper|other}';
        var output = _parse.parse(input);
        _assert.assert.equal(output.length, 1);
        _assert.assert.equal(output[0].type, 'reference');
        _assert.assert.equal(output[0].identifier.type, 'key');
        _assert.assert.equal(output[0].identifier.value, 'shane');
        _assert.assert.equal(output[0].filters.length, 2);
        _assert.assert.equal(output[0].filters[0], 'upper');
        _assert.assert.equal(output[0].filters[1], 'other');
    });
});