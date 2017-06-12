/*
USAGE: TODO

Script to download and merge books from your Downpour library
For some reason no one at Downpour can explain to me, it's impossible to download Downpour books as a flat file
As this makes managing your books a giant pain, I wrote this script to help automate the process

TODO: Detect and download metadata to inject into resulting file, because Downpour's files have zero metadata
 */

var bookTitle = process.argv[2];
var Nightmare = require('nightmare');
require('nightmare-download-manager')(Nightmare);

var nightmare = Nightmare({
  show: true
});

var library = 'a[href="https://www.downpour.com/my-library/"]';
var productSelector = '.product-library-item-link[title="' + bookTitle + '"]';
var downloadSelector = 'li#info-wrapper[data-title="' + bookTitle + '"]';
nightmare
    .downloadManager()
    .goto('https://www.downpour.com/customer/account/login')
    .insert('#email', 'USERNAME')
    .insert('#pass', 'PASSWORD')
    .click('#send2')
    .wait(library)
    .click(library)
    .wait(productSelector)
    .click(productSelector)
    .wait(1000)
    .evaluate(function(downloadSelector) {
      var download = document.querySelector(downloadSelector);
      var metadata = JSON.parse(download.querySelector('#manifest-data').getAttribute('data-manifest'));
      var filenames = Object.keys(metadata).filter(function (f) {
        return f.endsWith('.m4b')
      });
      var urls = [];
      for(let m4bFile of filenames) {
        urls.push(m4bFile);
        jQuery.ajax({
          type: "POST",
          async: false,
          url: 'https://www.downpour.com' + '/my-library/ajax/ajaxDLBookBD',
          data: {'bdfile': m4bFile},
          dataType: 'json',
          success: function (data) {
            if (data.status == 'success') {
              //window.location.href = data.link;
              urls.push(data.link)
            } else {
              urls.push("whoops: " + data.error);
            }
          }
        })
      }
      return urls;
    }, downloadSelector)
    .end()
    .then(function(result) {
      console.log(result);
    })
    .catch(function(error) {
      console.log(error);
    })
