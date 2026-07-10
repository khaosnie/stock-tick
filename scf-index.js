'use strict';
const fs = require('fs');
const path = require('path');

exports.main_handler = async (event, context) => {
  const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf-8');
  return {
    isBase64Encoded: false,
    statusCode: 200,
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
    body: html
  };
};
