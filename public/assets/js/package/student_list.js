$(document).ready(function(){
  flatpickr("#stdnt_reg_date", {
    dateFormat: "d-M-Y",
    allowInput: true,
    onOpen: function (selectedDates, dateStr, instance) {
      instance.setDate(instance.input.value, false);
    },
  });
});
$(document).ready(function(){
  flatpickr("#stdnt_dob", {
    dateFormat: "d-M-Y",
    allowInput: true,
    onOpen: function (selectedDates, dateStr, instance) {
      instance.setDate(instance.input.value, false);
    },
  });
});

function alertChecked(url){
  if( confirm("Are you sure want to delete ?")){
      window.location = url
  }
}
function isNumberMyKeys(evt) {
  evt = (evt) ? evt : window.event;
  var charCode = (evt.which) ? evt.which : evt.keyCode;
  if (charCode > 31 && (charCode < 48 || charCode > 57)) {
      return false;
  }
  return true;
}

function filter_student_list(){
  var usePath           = $.trim( $("#rootXPath").val() );
  $("form#myForms").submit();
}


function get_selected_address(){
  var stdnt_dtl_add1 = $("#stdnt_dtl_add1").val();
  var stdnt_dtl_add2 = $("#stdnt_dtl_add2").val();
  var stdnt_dtl_city = $("#stdnt_dtl_city").val();
  var curcity        = $("#curcity").val();
  var curadd1        = $("#curadd1").val();
  var curadd2        = $("#curadd2").val();
 
    if( $("input[name='stdnt_fam_check']").is(":checked") ){
        $("#stdnt_fam_add11").val(stdnt_dtl_add1);
        $("#stdnt_fam_add21").val(stdnt_dtl_add2);
        $("#stdnt_fam_city1").val(stdnt_dtl_city);
    }else{
        $("#stdnt_fam_add11").val(curadd1);
        $("#stdnt_fam_add21").val(curadd2);
        $("#stdnt_fam_city1").val(curcity);
    }
}

function general_next_process(){
  $("#student_detail").removeClass("is-active");
  $("#parents_detail").removeClass("is-active");    
  $("#student_detail_1").removeClass("is-active");
  $("#parents_detail_1").removeClass("is-active");
  $("#general_details").removeClass("is-active").addClass("is-active");
  $("#general_details_1").removeClass("is-active").addClass("is-active");
  
  
}

function set_global_focus(id){
  $("#"+id).focus();
}

function process_save_student_details(){
  var usePath           = $.trim( $("#rootXPath").val() );
  var formData          = new FormData();
  var other_data        = $('form#myforms').serializeArray();
  var mid               = $.trim( $("#mid").val() ); 
  var stdnt_reg_no      = $.trim( $("#stdnt_reg_no").val() );
  var stdnt_reg_date    = $.trim( $("#stdnt_reg_date").val() );
  var stdnt_fname       = $.trim( $("#stdnt_fname").val() ); 
  var stdnt_dob         = $.trim( $("#stdnt_dob").val() );
  var stdnt_gender      = $.trim( $("#stdnt_gender").val() );
  var bloodgroup        = $.trim( $("#stdnt_bloodgroup").val() ); 
  var stdnt_dtl_crse    = $.trim( $("#stdnt_dtl_crse").val() );  
  var stdnt_dtl_cat     = $.trim( $("#stdnt_dtl_cat").val() );
  var stdnt_dtl_add1    = $.trim( $("#stdnt_dtl_add1").val() ); 
  var stdnt_dtl_city    = $.trim( $("#stdnt_dtl_city").val() );
  var stdnt_dtl_nat     = $.trim( $("#stdnt_dtl_nat").val() );	
  var stdnt_dtl_aadhaar = $.trim( $("#stdnt_dtl_aadhaar").val() );	
  var stdnt_dtl_cont    = $.trim( $("#stdnt_dtl_cont").val() );	
  var image         = $('#stdnt_img').get(0).files[0];
  var signature         = $('#stdnt_signature').get(0).files[0];
  var pwdcertificate    = $('#stdnt_dtl_pwdcertificate').get(0).files[0];
 // var stdnt_dtl_email      = $.trim( $("#stdnt_dtl_email").val() );	

  if( stdnt_reg_no == ''){
    showToast("error","Registration number is required.");
    setTimeout(function(){ set_global_focus('stdnt_reg_no');},500);
    return false;
  }else if( stdnt_reg_date == ''){
    showToast("error","Registration date is required.");
    setTimeout(function(){ set_global_focus('stdnt_reg_date');},500);
    return false;
  }else if( stdnt_fname == ''){
    showToast("error","First name is required.");
    setTimeout(function(){ set_global_focus('stdnt_fname');},500);
    return false;
  }else if( stdnt_dob == ''){
    showToast("error","Date of Birth is required.");
    setTimeout(function(){ set_global_focus('stdnt_dob');},500);
    return false;
  }else if( stdnt_gender == ''){
    showToast("error","Gender is required.");
    setTimeout(function(){ set_global_focus('stdnt_gender');},500);
    return false;
  }else if( stdnt_dtl_crse == ''){
    showToast("error","Course code is required.");
    setTimeout(function(){ set_global_focus('stdnt_dtl_crse');},500);
    return false;
  }else if( stdnt_dtl_cat == ''){
    showToast("error","Category is required.");
    setTimeout(function(){ set_global_focus('stdnt_dtl_cat');},500);
    return false;
  }else if( stdnt_dtl_cont == ''){
    showToast("error","Contact number is required.");
    setTimeout(function(){ set_global_focus('stdnt_dtl_cont');},500);
    return false;
  }else if( stdnt_dtl_add1 == ''){
    showToast("error","Address 1 is required.");
    setTimeout(function(){ set_global_focus('stdnt_dtl_add1');},500);
    return false;
  // }else if( stdnt_dtl_city == ''){
  //   showToast("error","City is required.");
  //   setTimeout(function(){ set_global_focus('stdnt_dtl_city');},500);
  //   return false;
  }else if( stdnt_dtl_nat == ''){
    showToast("error","Nationality is required.");
    setTimeout(function(){ set_global_focus('stdnt_dtl_nat');},500);
    return false;
  }
   
  formData.append("identity", "STDNT");
  formData.append("mid", mid);  
  if( typeof(signature) != "undefined" ){
    formData.append("stdnt_signature", signature); 
  }else{
  formData.append("stdnt_signature", '');
  }
  if( typeof(signature) != "undefined" ){
    formData.append("stdnt_img", image); 
  }else{
  formData.append("stdnt_img", '');
  }
  if( typeof(signature) != "undefined" ){
    formData.append("stdnt_dtl_pwdcertificate", pwdcertificate);
  }else{
    formData.append("stdnt_dtl_pwdcertificate", '');
  } 
 
  $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });
  
   $(".no_loader").removeClass("hidden").addClass("hidden");
   $(".loader").removeClass("hidden");
    setTimeout(function(){
  $.ajax({
          url: usePath+"student_list/ajax_process",
          type: 'POST',
          data: formData,
          async: false,
          contentType: false,
          processData: false,
          success: function (resp) {
            
            if( resp.status ){
              $("#mid").val(resp.profileid);
              $("#currcategoryimage").val(resp.profileimage);
              $("#cursignature").val(resp.signimages);
              $("#mdid").val(resp.mdid);
              $("#curcertificate").val(resp.mdfiles);
              $("#student_detail").removeClass("is-active");
              $("#parents_detail").removeClass("is-active").addClass("is-active");    
              $("#student_detail_1").removeClass("is-active");
              $("#parents_detail_1").removeClass("is-active").addClass("is-active"); 
              $(".no_loader").removeClass("hidden");
               $(".loader").removeClass("hidden").addClass("hidden");                          
              showToast("success",resp.message);                  
                    
            }else{  
              $(".no_loader").removeClass("hidden");
               $(".loader").removeClass("hidden").addClass("hidden");                         
              showToast("success",resp.message); 
            }

          },
          error: function () {
            $(".no_loader").removeClass("hidden");
            $(".loader").removeClass("hidden").addClass("hidden");
              $(".process_save").show();
          },
          cache: false
           });

    },500);
}

function process_student_family() {
  var usePath              = $.trim( $("#rootXPath").val() );
  var formData             = new FormData();
  var other_data           = $('form#student_parent_detail').serializeArray();
  var mid                  = $.trim( $("#qualiffooterid1").val() );

  $.each(other_data,function(key,input){
    formData.append(input.name,input.value);
  });
  var stdnt_fam_code = $.trim( $("#stdnt_reg_no").val() ); 
  formData.append("identity", "PRNTDTLS");
  formData.append("qualiffooterid", mid);
  formData.append("stdnt_reg_no", stdnt_fam_code); 
  $(".no_loader").removeClass("hidden").addClass("hidden");
  $(".loader").removeClass("hidden");     
  setTimeout(function(){
    $.ajax({
           url: usePath+"student_list/ajax_process",
           type: 'POST',
           data: formData,
           async: false,
           contentType: false,
           processData: false,
           success: function (resp) {               
              if( resp.status ){         

                $("#process_canidate_quli").html(resp.data);
                $(".no_loader").removeClass("hidden");
                $(".loader").removeClass("hidden").addClass("hidden");     
                setTimeout(function(){ reset_qualification_afteradd();},500);         
                       

              }else{
                  $(".no_loader").removeClass("hidden");
                  $(".loader").removeClass("hidden").addClass("hidden");     
                  $(".process_qualif_save").show();
                  showToast("error",resp.message); 
                
              }
           },
           error: function () {
            $(".no_loader").removeClass("hidden");
            $(".loader").removeClass("hidden").addClass("hidden");     
           },
           cache: false
   });

  },500);

}

function fill_my_qulification_data(id){
  var stdnt_fam_type1      =  $("#stdnt_fam_type"+id).val();
  var stdnt_fam_father1       =  $("#stdnt_fam_father"+id).val();
  var stdnt_fam_check1 =  $("#stdnt_fam_check"+id).val();   
  var stdnt_fam_add11       =  $("#stdnt_fam_add1"+id).val();
  var stdnt_fam_add21     =  $("#stdnt_fam_add2"+id).val();
  var stdnt_fam_city1        =  $("#stdnt_fam_city"+id).val();
  var stdnt_fam_tel_res1      =  $("#stdnt_fam_tel_res"+id).val();
  var stdnt_fam_tel_off1      =  $("#stdnt_fam_tel_off"+id).val();
  var stdnt_fam_email1      =  $("#stdnt_fam_email"+id).val();
  var stdnt_fam_occu1      =  $("#stdnt_fam_occu"+id).val();
  var stdnt_fam_income1      =  $("#stdnt_fam_income"+id).val();
  $("#stdnt_fam_type1").val(stdnt_fam_type1);
  $("#stdnt_fam_father1").val(stdnt_fam_father1);
  $("#stdnt_fam_check1").val(stdnt_fam_check1)    
  $("#stdnt_fam_add11").val(stdnt_fam_add11) ;
  $("#stdnt_fam_add21").val(stdnt_fam_add21);
  $("#stdnt_fam_city1").val(stdnt_fam_city1);
  $("#stdnt_fam_tel_res1").val(stdnt_fam_tel_res1);
  $("#stdnt_fam_tel_off1").val(stdnt_fam_tel_off1);
  $("#stdnt_fam_email1").val(stdnt_fam_email1);
  $("#stdnt_fam_occu1").val(stdnt_fam_occu1);
  $("#stdnt_fam_income1").val(stdnt_fam_income1);
  $(".process_qualif_save").show();
}

function process_qualif_edit(id,type,father,check1,address1,address2,city,resi,office,email,occup,income){
  // var stdnt_fam_type1        =  $("#stdnt_fam_type"+id).val();
  $(".process_qualif_save").hide();
  //  $("#stdnt_fam_type1").val(stdnt_fam_type1);
   $("#qualiffooterid1").val(id)
   $("#stdnt_fam_type1").val(type);
   $("#stdnt_fam_father1").val(father);
   if( check1 == 'Y'){
    $("#stdnt_fam_check1").prop("checked",true);
   }else{
    $("#stdnt_fam_check1").prop("checked",false);
   }   
   
   
   $("#stdnt_fam_add11").val(address1) ;
   $("#stdnt_fam_add21").val(address2);
   $("#stdnt_fam_city1").val(city);
   $("#stdnt_fam_tel_res1").val(resi);
   $("#stdnt_fam_tel_off1").val(office);
   $("#stdnt_fam_email1").val(email);
   $("#stdnt_fam_occu1").val(occup);
   $("#stdnt_fam_income1").val(income);
   $("#curcity").val(city);
   $("#curadd1").val(address1);
   $("#curadd2").val(address2);
   $(".process_qualif_save").show();


  // setTimeout(function(){ get_university_qualf_list('1'); },500);
  // setTimeout(function(){ fill_my_qulification_data(id); },500);
 
}

function reset_qualification_afteradd(){
  $("#qualiffooterid1").val('');
  $("#stdnt_fam_type1").val('')
  $("#stdnt_fam_father1").val('');
  $("#stdnt_fam_check1").val('') ;
  $("#stdnt_fam_add11").val('');
  $("#stdnt_fam_add21").val('');
  $("#stdnt_fam_tel_res1").val('');
  $('#stdnt_fam_tel_off1').val('');
  $("#stdnt_fam_email1").val('');
  $("#stdnt_fam_occu1").val('');
  $('#stdnt_fam_income1').val('');
  $(".process_qualif_save").show();
}

function get_university_qualf_list(id){
  var usePath        = $.trim( $("#rootXPath").val() );
  var qualification  = $.trim( $("#stdnt_fam_type"+id).val() );
  var occupation     = $.trim( $("#stdnt_fam_occu"+id).val() );
  if( qualification == 'Father'){
      $(".process_visibility").removeClass("hidden").addClass("hidden");
  }else if( qualification == 'Mother' ){
      $(".process_visibility").removeClass("hidden").addClass("hidden");
  }else{
       $(".process_visibility").removeClass("hidden");
  }
  if( occupation == 'Private Job'){
    $(".process_visibility").removeClass("hidden").addClass("hidden");
}else if( occupation == 'Govt. Job' ){
    $(".process_visibility").removeClass("hidden").addClass("hidden");
}else{
     $(".process_visibility").removeClass("hidden");
}
      // $.ajax({
      //              url: usePath+"sewadar_information/ajax_process",
      //              type: 'POST',
      //              data: {'qualification': qualification,'identity':'QLFUNV'},
      //              async: false,
      //              success: function (resp) {
      //                  if ( resp.status ){
      //                      var udata = resp.undata;
      //                      var qdata = resp.qldata;
      //                      $("#skq_universityboard"+id).html(udata);
      //                      $("#skq_degreedip"+id).html(qdata);
      //                  }else{
      //                      $("#skq_universityboard"+id).html('<option value="">-Select-</option>');
      //                      $("#skq_degreedip"+id).html('<option value="">-Select-</option>');
      //                  }


      //              },
      //              error: function () {
      //                      $("#skq_universityboard"+id).html('<option value="">-Select-</option>');
      //                      $("#skq_degreedip"+id).html('<option value="">-Select-</option>');
      //              },
      //              cache: false
      // });
      setTimeout(function(){ set_focusouted("stdnt_fam_father1"); },500);
}
function set_focusouted(id){
  $("#"+id).focus();
}
function change_row_qualification(id){
  var nhtml  = '';
  var val    = $('.new_qualification select[name="stdnt_fam_father[]"]:last').prop("value");
  
  var lstid  = $('.new_qualification select[name="stdnt_fam_father[]"]:last').prop("id");
  var nid    = lstid.replace ( /[^\d.]/g, '' );
  
  var issm   = eval(nid)+eval(1);    
  var i      = issm;    
  //if( val != '' ){
      nhtml += '<tr >';
      nhtml += '<input type="hidden" class="form-control-sm" name="qualiffooterid[]" id="qualiffooterid'+i+'" value=""/>';
      nhtml += '<input type="hidden" class="form-control-sm" name="cur_qlf_attch[]" id="cur_qlf_attch'+i+'" value=""/>';
      nhtml += '<td>';
      nhtml += '<select class="form-control" name="stdnt_fam_type[]" id="stdnt_fam_type'+i+'" onchange="get_university_qualf_list('+i+');">';
      nhtml += '<option value="">-Select-</option>';
      nhtml += '<option value="Father"  >Father</option>';
      nhtml += '<option value="Mother" >Mother</option>';
      nhtml += '<option value="Guardian" >Guardian</option>';
      nhtml += '</select>';
      nhtml += '</td>';
      nhtml += '<td>';
      nhtml += '<select class="form-control" name="stdnt_fam_father[]" id="stdnt_fam_father'+i+'" >';
      nhtml += '<option value="">-Select</option>';
      nhtml += '</select>';
      nhtml += '</td>';
      nhtml += '<td>';
      nhtml += '<select class="form-control" name="stdnt_fam_add1[]" id="stdnt_fam_add1'+i+'">';
      nhtml += '<option value="">-Select</option>';
      nhtml += '</select>';
      nhtml += '</td>';
      

      nhtml += '<td><input type="text" class="form-control-sm " onkeypress="return isNumberKeys(event);" maxlength="4" name="stdnt_fam_add2[]" id="stdnt_fam_add2'+i+'" value=""/></td>';
      nhtml += '<td><input type="text" class="form-control-sm " onkeypress="return isNumberKeys(event);" maxlength="2" name="stdnt_fam_city[]" id="stdnt_fam_city'+i+'" value=""/></td>';
      nhtml += '<td><input type="text" class="form-control-sm " onkeypress="return isNumberFloatKey(event);" maxlength="10" name="skq_percenatge[]" id="skq_percenatge'+i+'" value=""/></td>';
      nhtml += '</tr>';
      $(".new_qualification:last").after(nhtml);
 
  
}


function delete_parent_detail(id){
  var usePath      = $.trim( $("#rootXPath").val() );    

  if( confirm("Are you sure you want to delete?")){
      window.location = usePath+"student_list/student_admission/"+id+"/deleteparent";
    }

}

function process_sewdar_office_step_second(){
  var usePath           = $.trim( $("#rootXPath").val() );
  var formData          = new FormData();
  var other_data        = $('form#student_general_detail').serializeArray();
  var stdnt_gn_code     = $.trim( $("#stdnt_reg_no").val() );

  var stdnt_gn_nhmc     = $.trim( $("#stdnt_gn_nhmc").val() );
  var stdnt_gn_cur_sem  = $.trim( $("#stdnt_gn_cur_sem").val() );
  if( stdnt_gn_code == ''){
    showToast("error","Registration number is required.");
    setTimeout(function(){ set_global_focus('stdnt_reg_no');},500);
    return false;
  }else if( stdnt_gn_nhmc == ''){
    showToast("error","NCHM No. is required.");
    setTimeout(function(){ set_global_focus('stdnt_gn_nhmc');},500);
    return false;
  }
  else if( stdnt_gn_cur_sem == ''){
   showToast("error","Current Semester is required.");
    setTimeout(function(){ set_global_focus('stdnt_gn_cur_sem');},500);
    return false;
  }
 
  formData.append("identity", "GNRLDTLS");
  formData.append("stdnt_reg_no", stdnt_gn_code);
  $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
  });
  
  $(".nogloader").removeClass("hidden").addClass("hidden");
  $(".gloader").removeClass("hidden");
   
  setTimeout(function(){
    $.ajax({
                   url: usePath+"student_list/ajax_process",
                   type: 'POST',
                   data: formData,
                   async: false,
                   contentType: false,
                   processData: false,
                   success: function (resp) {
                      
                      if( resp.status ){                            
                             showToast("success",resp.message);
                             $(".nogloader").removeClass("hidden");
                             $(".gloader").removeClass("hidden").addClass("hidden");
                             window.location = usePath+"student_list"
                             
                      }else{                           
                             showToast("error",resp.message);
                            $(".nogloader").removeClass("hidden");
                            $(".gloader").removeClass("hidden").addClass("hidden");
                          
                      }

                   },
                   error: function () {
                       $(".nogloader").removeClass("hidden");
                       $(".gloader").removeClass("hidden").addClass("hidden");
                       $(".process_save").show();
                   },
                   cache: false
           });

          },500);
}


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

$('.item-img').on('change', function () {
  readFile(this);
});

$('#cropImageBtn').on('click', function () {
  $uploadCrop.croppie('result', {
    type: 'base64',
    format: 'png',
    size: {width: 300, height: 300}
  }).then(function (resp) {
    $('#item-img-output').attr('src', resp);
    $("#studentattach_file").val(resp);
    $('#cropImagePop').modal('hide');
    $('.example-image-link').attr('href', resp);    // Update the href in the anchor tag
  });
});

function updateSemesters() {
  var usePath = $.trim($("#rootXPath").val());
  var course_code = $.trim($("#stdnt_dtl_crse").val());
  var selectedSemester = $("#stdnt_gn_cur_sem").data("selected-semester"); // Get the preselected semester

  $.ajax({
      url: usePath + 'student_list/ajax_process',
      type: 'POST',
      data: { "course_code": course_code, identity: 'SEMESTER' },
      async: false,
      success: function (resp) {
          var vhtml = '<option value="">-Select-</option>';
          if (resp.status) {
              var sdata = resp.data;
              $.each(sdata, function (index, semester) {
                  var selected = (semester == selectedSemester) ? 'selected' : '';
                  vhtml += '<option value="' + semester + '" ' + selected + '>Semester ' + semester + '</option>';

              });
          }
          $("#stdnt_gn_cur_sem").html(vhtml);
      },
      error: function () {
          console.error('Error fetching semesters');
      },
      cache: false
  });
}


$(document).ready(function () {
  const tableId = '#example4';  
  // Check if the table is already initialized
  if ($.fn.DataTable.isDataTable(tableId)) {
    $(tableId).DataTable().destroy();     }  
  // Initialize the DataTable
  $(tableId).DataTable({
    paging: true,
    pagingType: "full_numbers", // Show full pagination controls
    lengthMenu: [500, 750, 1000], // Rows per page
    pageLength: 10, // Default rows per page
    language: {
      paginate: {
        first: "First",
        last: "Last",
        next: "Next",
        previous: "Previous",
      },
    },
    drawCallback: function () {
      // Force all page numbers to display without ellipses
      $('.dataTables_paginate .ellipsis').remove();
      
    },
  });
  setTimeout(function(){ set_data_table_remove_elipse_no();},500);
});


function set_data_table_remove_elipse_no(){
  var counterpage = $.trim( $("#perpage_index").val() ) >0 ? $.trim( $("#perpage_index").val() ) : 1;
//   $("li.paginate_button a").each(function(){
//         var indexvl = $.trim( $(this).text() )>0 ? $.trim( $(this).text() ) : '';
//         if( indexvl!=''){
//             if( counterpage == indexvl){
               
//             }
//         }
       
//   });
 if( counterpage>1 ){
    var counters = eval(counterpage)+1;
    
    $('a[data-dt-idx="'+counters+'"]').click();
 }
}
