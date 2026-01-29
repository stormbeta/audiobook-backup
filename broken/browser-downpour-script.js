//TODO: No longer functional, website was redesigned
// New design is much more tedious, not sure how to fix script

// ==UserScript==
// @name         Downpour Downloader
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Downpour makes it extremely inconvenient to download books as a simple single file, so this lets you download them all at once by right-clicking on the book
// @author       stormbeta@gmail.com
// @match        https://www.downpour.com/my-library
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function initMenu(aEvent) {
        // Executed when user right click on web page body
        // aEvent.target is the element you right click on
        var node = aEvent.target;
        while(node.getAttribute('data-book_id')===null) {
            node = node.parentElement;
        }
        var book_id = node.getAttribute('data-book_id');
        console.log(book_id);
        var bsa_root = 'https://www.downpour.com';
        jQuery.ajax({
            type: 'POST',
            url: bsa_root + '/my-library/ajax/ajaxGetBookActionOptions',
            dataType: 'json',
            data: {'bookId': book_id},
            success: function(data) {
                window.results = [];
                window.results2 = [];
                for(var filename in data.manifest) {
                    if(filename.endsWith('m4b')) {
                        window.results.push(jQuery.ajax({
                            type: 'POST',
                            url: bsa_root + '/my-library/ajax/ajaxDLBookBD',
                            dataType: 'json',
                            data: {'bdfile': filename},
                            success: function (data2) {
                                console.log(data2.link);
                                //window.results2.push(data2.link);
                                var a = document.createElement('a');
                                a.href = data2.link;
                                a.target = '_parent';
                                (document.body || document.documentElement).appendChild(a);
                                window.results2.push(a);
                            }
                        }));
                    }
                }
                jQuery.when.apply(null, window.results).done(function(){
                    console.log(window.results2);
                    for(var i=0; i < window.results2.size(); i++) {
                        console.log("HEY: " + window.results2[i]);
                        //window.location.href = window.results2[i];
                        window.open(results2[i].href);
                    }
                });
            }
        });

    }

    var body = document.body;
    body.addEventListener("contextmenu", initMenu, false);

})();
