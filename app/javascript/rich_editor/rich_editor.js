require('tinymce/themes/modern');
import tinymce from 'tinymce';

require('tinymce/skins/lightgray/content.min.css');
require('tinymce/skins/lightgray/skin.min.css');

require('tinymce/plugins/code');
require('tinymce/plugins/link');
require('tinymce/plugins/anchor');
require('tinymce/plugins/paste');
require('tinymce/plugins/searchreplace');
require('tinymce/plugins/lists');
require('tinymce/plugins/textcolor');
require('tinymce/plugins/colorpicker');
require('tinymce/plugins/fullscreen');
require('tinymce/plugins/charmap');
require('tinymce/plugins/hr');

require('./rich_editor.scss');

$(document).ready(() => {
  tinymce.init({
    selector: 'textarea.rich-editor',
    //necessary skin files are included above
    skin: false,
    plugins: 'code link anchor paste searchreplace lists textcolor colorpicker fullscreen charmap hr',
    toolbar: [
      'cut copy paste pastetext | undo redo | searchreplace | bold italic underline strikethrough subscript superscript | removeformat | hr charmap',
      'numlist bullist | outdent indent | blockquote | alignleft aligncenter alignright alignjustify | link unlink anchor  | code fullscreen',
      'styleselect formatselect fontselect fontsizeselect | forecolor backcolor'
    ],
    branding: false,
    setup: function (theEditor) {
      theEditor.on('focus', function () {
        $(this.contentAreaContainer.parentElement).find("div.mce-toolbar-grp").show();
        $(this.contentAreaContainer.parentElement).find("div.mce-menubar").show();
        $(this.contentAreaContainer.parentElement).find("div.mce-statusbar").show();
      });
      theEditor.on('blur', function () {
        $(this.contentAreaContainer.parentElement).find("div.mce-toolbar-grp").hide();
        $(this.contentAreaContainer.parentElement).find("div.mce-menubar").hide();
        $(this.contentAreaContainer.parentElement).find("div.mce-statusbar").hide();
      });
      theEditor.on("init", function () {
        $(this.contentAreaContainer.parentElement).find("div.mce-toolbar-grp").hide();
        $(this.contentAreaContainer.parentElement).find("div.mce-menubar").hide();
        $(this.contentAreaContainer.parentElement).find("div.mce-statusbar").hide();
      })}
    }
  )
});

