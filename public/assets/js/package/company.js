
var $uploadCrop, rawImg;

function readFile(input) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();
    reader.onload = function (e) {
      $('.upload-demo').addClass('ready');
      $('#cropImagePop').modal('show');
      rawImg = e.target.result;
    }
    reader.readAsDataURL(input.files[0]);
  } else {
    alert("Sorry - your browser doesn't support the FileReader API");
  }
}

$uploadCrop = $('#upload-demo').croppie({
  viewport: {
    width: 300,
    height: 300
  },
  enforceBoundary: false,
  enableExif: true
});

$('#cropImagePop').on('shown.bs.modal', function() {
  $uploadCrop.croppie('bind', {
    url: rawImg
  }).then(function() {
    console.log('jQuery bind complete');
  });
});

$('.img-thumbnail').on('change', function () {
  readFile(this);
});

$('#cropImageBtn').on('click', function () {
  $uploadCrop.croppie('result', {
    type: 'base64',
    format: 'png',
    size: {width: 300, height: 300}
  }).then(function (resp) {
    $('#previewCompFile').attr('src', resp); // Ensure this ID matches
    $("#currentcomplogo").val(resp); // Updated hidden input with base64 data
    $('#cropImagePop').modal('hide');
    
  });
});


var $uploadCro, rawIm;

function readFil(input) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();
    reader.onload = function (e) {
      $('.upload-demo').addClass('ready');
      $('#cropImagePop').modal('show');
      rawIm = e.target.result;
    }
    reader.readAsDataURL(input.files[0]);
  } else {
    alert("Sorry - your browser doesn't support the FileReader API");
  }
}

$uploadCro = $('#upload-demo').croppie({
  viewport: {
    width: 300,
    height: 300
  },
  enforceBoundary: false,
  enableExif: true
});

$('#cropImagePop').on('shown.bs.modal', function() {
  $uploadCro.croppie('bind', {
    url: rawIm
  }).then(function() {
    console.log('jQuery bind complete');
  });
});

$('.img-thumbnai').on('change', function () {
  readFil(this);
});

$('#cropImageBtn').on('click', function () {
  $uploadCro.croppie('result', {
    type: 'base64',
    format: 'png',
    size: {width: 300, height: 300}
  }).then(function (resp) {
    $('#previewSignFile').attr('src', resp); // Ensure this ID matches
    $("#currentcompsigns").val(resp); // Updated hidden input with base64 data
    $('#cropImagePop').modal('hide');
    
  });
});

function isFloatNegativeKey(e,vls){

	  if (e.charCode >= 32 && e.charCode < 127 && !/^-?\d*[.,]?\d*$/.test(vls + '' + String.fromCharCode(e.charCode)))
	  {
		return false;
	  }
	  return true;
}

function isNumberFloatKey(evt)
 {
	  var charCode = (evt.which) ? evt.which : evt.keyCode;
	  if (charCode != 46 && charCode > 31 && (charCode < 48 || charCode > 57)){
		  return false;
	  }
	  return true;
   }

function isNumberKeys(evt) {
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    if (charCode > 31 && (charCode < 48 || charCode > 57)) {
        return false;
    }
    return true;
}

$('.mdl-tabs__tab').click(function() {
	var target = $(this).attr('href');
	$('.mdl-tabs__panel').removeClass('is-active');
	$(target).addClass('is-active');
  });
  