var $uploadCrop, rawImg;

// Function for handling image upload (photo)
function readFileImage(input) {
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

$('.item-img').on('change', function () {
  readFileImage(this);  // Use the function for image upload
});

$('#cropImageBtn').on('click', function () {
  $uploadCrop.croppie('result', {
    type: 'base64',
    format: 'png',
    size: { width: 300, height: 300 }
  }).then(function (resp) {
    $('#item-img-output').attr('src', resp);
    $("#studentattach_file").val(resp);
    $('#cropImagePop').modal('hide');
  });
});

// For signature upload
var $uploadCro, rawSignImg;

// Function for handling signature upload
function readFileSignature(input) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();
    reader.onload = function (e) {
      $('.upload-dem').addClass('ready');
      $('#signImagePop').modal('show');
      rawSignImg = e.target.result;
    }
    reader.readAsDataURL(input.files[0]);
  } else {
    alert("Sorry - your browser doesn't support the FileReader API");
  }
}

$uploadCro = $('#upload-dem').croppie({
  viewport: {
    width: 300,
    height: 300
  },
  enforceBoundary: false,
  enableExif: true
});

$('#signImagePop').on('shown.bs.modal', function() {
  $uploadCro.croppie('bind', {
    url: rawSignImg
  }).then(function() {
    console.log('jQuery bind complete');
  });
});

$('.sign-item-img').on('change', function () {
  readFileSignature(this);  // Use the function for signature upload
});

$('#cropImageBt').on('click', function () {
  $uploadCro.croppie('result', {
    type: 'base64',
    format: 'png',
    size: { width: 300, height: 300 }
  }).then(function (resp) {
    $('#sign-item-img-output').attr('src', resp);
    $("#studentattach_fil").val(resp);
    $('#signImagePop').modal('hide');
  });
});

function set_global_focus(id){
  $("#"+id).focus();
}

function isNumberMyKeys(evt) {
  evt = (evt) ? evt : window.event;
  var charCode = (evt.which) ? evt.which : evt.keyCode;
  if (charCode > 31 && (charCode < 48 || charCode > 57)) {
      return false;
  }
  return true;
}

var isOTPVerified = false;  // Flag to check OTP verification status

function process_save_student_details(event) {
  event.preventDefault();  // Prevent default form submission
  var usePath = $.trim($("#rootXPath").val());
  var formData = new FormData();
  var other_data = $('form#myforms').serializeArray();
  var mid = $.trim($("#mid").val());
  var stdnt_reg_no = $.trim($("#stdnt_reg_no").val());
  var std_otp = $.trim($("#std_otp").val());
  var signature = $('#stdnt_signature').get(0).files[0];
  var stdnt_img = $('#stdnt_img').get(0).files[0];

  // Validate required fields before submission
  if (stdnt_reg_no === '') {
    showToast("error", "Registration number is required.");
    set_global_focus('stdnt_reg_no');
    return false;
  }

 if (std_otp === '') {
    showToast("error", "OTP is required.");
    set_global_focus('std_otp');
    return false;
  }
  // Verify OTP before proceeding with form submission
  verify_registration_otp(function(isOTPValid) {
    if (!isOTPValid) {
      showToast("error", "Invalid OTP. Please verify the OTP before submitting.");
      return false;  // Stop form submission if OTP is invalid
    }

    // OTP is valid, proceed with form data submission
    formData.append("identity", "STDNT");
    formData.append("mid", mid);
    formData.append("stdnt_reg_no", stdnt_reg_no);
    if (signature) formData.append("stdnt_signature", signature);
    if (stdnt_img) formData.append("stdnt_img", stdnt_img);
    $.each(other_data, function(key, input) {
      formData.append(input.name, input.value);
    });

    $.ajax({
      url: usePath + "student_info/ajax_process",
      type: 'POST',
      data: formData,
      contentType: false,
      processData: false,
      success: function(resp) {
        if (resp.status) {
          $("#mid").val(resp.profileid);
          $("#currcategoryimage").val(resp.profileimage);
          $("#cursignature").val(resp.signimages);
          showToast("success", "Your Profile and Signature are Updated.");
          setTimeout(function(){ reset_entire_variable();},500);
          // Reset form fields and clear image previews
          $('form#myforms').trigger('reset');
          $('#item-img-output').attr('src', ''); // or set to a default image path
          $('#sign-item-img-output').attr('src', ''); // or set to a default image path
        } else {
          showToast("error", resp.message);
        }
      },
      error: function() {
        showToast("error", "An error occurred while processing.");
      }
    });
  });
}
function reset_entire_variable(){
  window.location  = window.location.href;
}

function verify_registration_otp(callback) {
  var usePath = $("#rootXPath").val();
  var formData = new FormData();
  var otp = $.trim($("#std_otp").val()) !== '' ? btoa($.trim($("#std_otp").val())) : '';
  var registno = $.trim($("#stdnt_reg_no").val()) !== '' ? btoa($.trim($("#stdnt_reg_no").val())) : '';

  formData.append("otp", otp);
  formData.append("registno", registno);
  formData.append("identity", 'VRFOTP');

  $.ajax({
    url: usePath + "student_info/ajax_process",
    type: 'POST',
    data: formData,
    contentType: false,
    processData: false,
    success: function(resp) {
      $("#verfify_otp_link").removeClass("hidden").addClass("hidden");
      if (resp.status) {
        showToast("success", "OTP Verified");
        callback(true);  // OTP is valid
      } else {
        showToast("error", resp.message);
        $("#std_otp").val('');
        callback(false);  // OTP is invalid
      }
    },
    error: function() {
      showToast("error", "Failed to verify OTP.");
      callback(false);  // Error occurred during OTP verification
    }
  });
}

function sendOTPEmail() {
  var usePath = $.trim($("#rootXPath").val());
  var regNo = $.trim($("#stdnt_reg_no").val());
  event.preventDefault();  // Prevent default form submission

  if (regNo === '') {
    showToast("error", "Registration number is required.");
    setTimeout(function() { set_global_focus('stdnt_reg_no'); }, 500);
    return false;
  }

  // Show the loader when the request starts
  $(".show_loader").removeClass("hidden");
  $(".no_loader").addClass("hidden");

  $.ajax({
    url: usePath + "student_info/ajax_process",
    type: 'POST',
    data: {
      'stdnt_reg_no': regNo,
      'identity': 'EMAIL'
    },
    success: function(resp) {
      if (resp.status) {
        showToast("success", "Email has been sent to the user.");
      } else {
        showToast("error", resp.message);
      }
    },
    error: function(xhr, status, error) {
      console.error('Error:', error);
      alert('Failed to send email');
    },
    complete: function() {
      // Hide the loader after a short delay (immediate or after success)
      setTimeout(function() {
        $(".show_loader").addClass("hidden");
        $(".no_loader").removeClass("hidden");
      }, 3000);  // Set a timeout of 3 seconds before hiding the loader
    }
  });

  // Ensure loader is hidden after a timeout even if AJAX hangs
  setTimeout(function() {
    $(".show_loader").addClass("hidden");
    $(".no_loader").removeClass("hidden");
  }, 3000);  // Loader will be hidden after 3 seconds
}

function check_opt_for_verify() {
  var newopt = $.trim($("#std_otp").val());
  if (newopt.length > 5) {
    $("#verfify_otp_link").removeClass("hidden");
    setTimeout(function() { verify_registration_otp(); }, 500);
  }
}
