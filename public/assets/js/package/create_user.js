
function isNumberMyKeys(evt) {
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    if (charCode > 31 && (charCode < 48 || charCode > 57)) {
        return false;
    }
    return true;
  }

  $(document).on("click","#city_name_type_select",function(){
    $("#sidebar-menu-toggle").toggle();
  });
  function close_city_checkbox(){
    $("#sidebar-menu-toggle").hide();
  }
  $(document).ready(function() {
      // Function to handle clicking outside the menu to close it
      $(document).click(function(event) {
        var menu = $('#sidebar-menu-toggle');
        var toggleButton = $('#city_name_type_select');
    
        // Check if the click is outside the menu and the toggle button
        if (!menu.is(event.target) && menu.has(event.target).length === 0 &&
            !toggleButton.is(event.target) && toggleButton.has(event.target).length === 0) {
              close_city_checkbox();
        }
      });
  });
  function close_city_checkbox(){
    $("#sidebar-menu-toggle").hide();
  }
  
  function get_selected_item_val(){
    var selectedValues = [];
    var xvalues = [];
    var postype = []
    $("input[name='city_type_select[]']:checked").each(function(){
      postype.push($(this).attr("id"));
      xvalues.push($(this).val());
      selectedValues.push($(this).val());
    });
    if(xvalues.length > 0){
      var xvaluesJoined = xvalues.join(",");
      var postypeJoined = postype.join(",");
      $("#city_name").val(postypeJoined);
      $("#city_name_type_select").val(xvaluesJoined);
    }else{
      $("#city_name").val('');
      $("#city_name_type_select").val('');
    }
  }
  
  function filter_user_list(){
    var useroot = $("#rootXPath").val();
    $(".show_loader").removeClass("hidden");
    $(".no_loader").removeClass("hidden").addClass("hidden")
    $("#myForms").attr("action",useroot+"create_user/user_list/search");
    $("#myForms").submit();
}

function reset_user_password(reqid,userid,username){
  $("#popup_requestid").val(reqid);
  $("#popup_userid").text(userid);
  $("#popup_username").text(username);
  setTimeout(function(){ },500);
  }

     // Function to handle showing/hiding password fields based on selected option
function showHidePasswordFields(option) {
  const newPasswordField = document.getElementById('new_password');
  if (option === 'autoGenerate') {
      newPasswordField.value = generatePassword(); // Function that generates a password
      newPasswordField.type = 'password';
      newPasswordField.readOnly = true;
  } else if (option === 'createNew') {
      newPasswordField.value = '';
      newPasswordField.type = 'password';
      newPasswordField.readOnly = false;
  }
}


  // Function to generate a random password (You can use your implementation here)
function generatePassword() {
  const length = 10; // Define the length of the generated password
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+{}[]|:;"<>,.?/~'; // Define the characters used in the password
  let password = '';

  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * charset.length);
    password += charset[randomIndex];
  }

  return password;
}

function togglePasswordField() {
  const passwordField = document.getElementById('new_password');
  const toggleIcon = document.getElementById('togglePassword');

  if (passwordField.type === 'password') {
      passwordField.type = 'text';
      toggleIcon.classList.remove('fa-eye');
      toggleIcon.classList.add('fa-eye-slash');
  } else {
      passwordField.type = 'password';
      toggleIcon.classList.remove('fa-eye-slash');
      toggleIcon.classList.add('fa-eye');
  }
}

async function copyPasswordToClipboard() {
  const newPasswordField = document.getElementById('new_password');

  // Check if the new_password field has a value
  if (!newPasswordField.value) {
    alert('Password field is empty. Please enter a password.');
    return; // Exit the function if the password field is empty
  }

  try {
    await navigator.clipboard.writeText(newPasswordField.value);
    alert('Text copied to clipboard');
  } catch (err) {
    alert('Unable to copy text to clipboard. Error: ' + err);
  }
}

function process_reset_user_password() {
  var usePath = $.trim($("#rootXPath").val());
  var new_pass = $.trim($("#new_password").val());
  var requestid = $.trim($("#popup_requestid").val());

  if (new_pass === '') {
    alert("New Password is required");
    $("#new_password").focus();
    return false;
  } else if (requestid === '') {
    alert("User ID is required.");
    return false;
  }
  $(".unprocess_loader").removeClass("hidden");
  $(".process_loader").addClass("hidden");

 
    $.ajax({
      url: usePath + "create_user/ajax_process",
      type: 'POST',
      data: { 'reqid': requestid, 'new_pass': new_pass,'identity': 'RESET' },
      async: false,
      success: function (resp) {
        $(".unprocess_loader").addClass("hidden");
        $(".process_loader").removeClass("hidden");

        if (resp.status) {
          alert("Password reset successful.");
          //window.location = window.location.href;
        } else {
          alert("Unable to process");
        }
       
      },
      error: function () {
        $(".unprocess_loader").addClass("hidden");
        $(".process_loader").removeClass("hidden");
      },
      cache: false
    });
 
}

function show_create_check_user_listmodule(){  
  $("#myDIV").toggleClass("hidden")
  var classname = $("#process_side_updown").attr("class");
  if( classname == 'fa fa-plus text-success'){
      $("#process_side_updown").removeClass("fa fa-plus text-success").addClass("fa fa-minus text-danger");
  }else if( classname == 'fa fa-minus text-danger'){
      $("#process_side_updown").removeClass("fa fa-minus text-danger").addClass("fa fa-plus text-success");
  }
  
}

document.addEventListener('DOMContentLoaded', function() {
  // Find all select-all-module checkboxes and attach event listeners
  document.querySelectorAll('.select-all-module').forEach(function(selectAllCheckbox) {
    selectAllCheckbox.addEventListener('change', function() {
      var moduleId = this.getAttribute('data-module-id'); // Get the module ID from the attribute
      var checkboxes = document.querySelectorAll('.module-checkbox-' + moduleId); // Get all checkboxes inside the module
      var moduleCode = this.value; // Get the module code (module name)

      checkboxes.forEach(function(checkbox) {
        checkbox.checked = selectAllCheckbox.checked; // Set the checkbox state to match the select-all checkbox
      });

      updateSelectedModules();
    });
  });

  // Find all individual checkboxes and attach event listeners
  document.querySelectorAll('.module-checkbox').forEach(function(moduleCheckbox) {
    moduleCheckbox.addEventListener('change', function() {
      var moduleId = this.classList[1].split('-')[2]; // Extract module ID from the checkbox class
      var selectAllCheckbox = document.querySelector('#process_common_select_' + moduleId); // Get the select all checkbox for this module
      var allModuleCheckboxes = document.querySelectorAll('.module-checkbox-' + moduleId); // Get all checkboxes inside this module

      // Check if any checkbox in the module is checked
      var anyChecked = Array.from(allModuleCheckboxes).some(function(checkbox) {
        return checkbox.checked;
      });

      // Uncheck the select-all checkbox if all checkboxes are unchecked, else keep it checked
      selectAllCheckbox.checked = anyChecked;

      updateSelectedModules();
    });
  });

  // Function to update selected modules in the hidden input
  function updateSelectedModules() {
    var selectedModules = new Set(); // Use a Set to avoid duplicates

    // Check for each module if any checkbox is selected
    document.querySelectorAll('.select-all-module').forEach(function(selectAllCheckbox) {
      var moduleId = selectAllCheckbox.getAttribute('data-module-id');
      var moduleCode = selectAllCheckbox.value; // Get the module code (module name)

      var allModuleCheckboxes = document.querySelectorAll('.module-checkbox-' + moduleId);
      
      // If the "select all" checkbox is checked OR any menu checkbox is checked, add the module
      var anyChecked = Array.from(allModuleCheckboxes).some(function(checkbox) {
        return checkbox.checked;
      });

      if (selectAllCheckbox.checked || anyChecked) {
        selectedModules.add(moduleCode); // Add the module code to the set
      }
    });

    // Update the hidden input field with selected modules (comma-separated)
    document.querySelector('#selected_module').value = Array.from(selectedModules).join(',');
  }

  // Call the function on page load to ensure the input is up-to-date with preselected values
  updateSelectedModules();
});
function handleFormSubmit() {
  var usertype = $.trim($("#usertype").val());
  var faculty = $.trim($("#faculty").val());
  var username = $.trim($("#username").val());
  var userpassword = $.trim($("#userpassword").val());
  var phonenumber = $.trim($("#phonenumber").val());
  if( usertype == ''){
    showToast("error","Select User Type.");
    setTimeout(function(){ set_global_focus('usertype');},500);
    return false;
  }else if( faculty == ''){
    showToast("error","Select faculty.");
    setTimeout(function(){ set_global_focus('faculty');},500);
    return false;
  }else if( username == ''){
    showToast("error","Username is required.");
    setTimeout(function(){ set_global_focus('username');},500);
    return false;
  // }else if( userpassword == ''){
  //   showToast("error","Password is required.");
  //   setTimeout(function(){ set_global_focus('userpassword');},500);
  //   return false;
  }else if( phonenumber == ''){
    showToast("error","Phone number is required.");
    setTimeout(function(){ set_global_focus('phonenumber');},500);
    return false;
  }
  // if (userpassword.length < 6) {
  //   showToast("error", "Password must be at least 6 characters long.");
  //   setTimeout(function(){ set_global_focus('userpassword');}, 500);
  //   return false; // Prevent form submission
  // }
  if (phonenumber.length !== 10) {
    showToast("error","Please enter a valid 10-digit phone number.");
    setTimeout(function(){ set_global_focus('phonenumber');},500);
    return false; // Prevent form submission
  }
  // Function to update selected modules in the hidden input
  var selectedModules = new Set(); // Use a Set to avoid duplicates
  var moduleCheckedStatus = 1; // Default to 1, meaning module is fully checked

  // Check for each module if any checkbox is selected
  document.querySelectorAll('.select-all-module').forEach(function(selectAllCheckbox) {
    var moduleId = selectAllCheckbox.getAttribute('data-module-id');
    var moduleCode = selectAllCheckbox.value; // Get the module code (module name)

    var allModuleCheckboxes = document.querySelectorAll('.module-checkbox-' + moduleId);
    
    // If any menu checkbox inside the module is checked, add the module code
    var anyChecked = Array.from(allModuleCheckboxes).some(function(checkbox) {
      return checkbox.checked;
    });

    if (anyChecked) {
      selectedModules.add(moduleCode); // Add the module code to the set
    }

    // Check if all checkboxes inside the module are checked
    var allChecked = Array.from(allModuleCheckboxes).every(function(checkbox) {
      return checkbox.checked;
    });

    // If any checkbox is unchecked, set moduleCheckedStatus to 0
    if (!allChecked) {
      moduleCheckedStatus = 0;
    }
  });

  // Update the hidden input fields with the module data
  document.querySelector('#selected_module').value = Array.from(selectedModules).join(',');
  document.querySelector('#module_checked_status').value = moduleCheckedStatus;

  // Validate if at least one module is selected
  if (selectedModules.size === 0) {
    showToast("error","Please select at least one module before submitting.");
    return false; // Prevent form submission
  }

  // If validation passes, submit the form
  document.querySelector('form').submit();
}


