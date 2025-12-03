
function get_global_semester(){
  setTimeout(function(){ changeFeeList(); },500);
  setTimeout(function(){ updateSemester(); },500);
}

function updateSemester() {
    var usePath = $.trim($("#rootXPath").val());
    var fee_crse = $.trim($("#fee_crse").val());
    var selectedSemester = $("#fee_sem").data("selected-semester"); // Get the preselected semester
    
    $.ajax({
        url: usePath + 'fee_list/ajax_process',
        type: 'POST',
        data: { "fee_crse": fee_crse, identity: 'SEMESTER' },
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
            $("#fee_sem").html(vhtml);
        },
        error: function () {
            console.error('Error fetching semesters');
        },
        cache: false
    });
}

function changeFeeList(){  
    var fee_crse = $("#fee_crse").val();
    var fee_year = $("#fee_year").val();
    var fee_currncy=$("#fee_currncy").val();
    var fee_sem=$("#fee_sem").val();
    setTimeout(function(){ show_list(fee_crse,fee_year,fee_currncy,fee_sem);},500);
}


function set_global_focus(id){
  $("#"+id).focus();
}

function show_list(fee_crse,fee_year,fee_currncy,fee_sem) {
    var usePath = $("#rootXPath").val();
    var formData = new FormData();
    var fee_year      = $.trim( $("#fee_year").val() );
    var fee_crse      = $.trim( $("#fee_crse").val() );
    var fee_catgry      = $.trim( $("#fee_catgry").val() );
    var fee_currncy      = $.trim( $("#fee_currncy").val() );
    var fee_sem         = $.trim( $("#fee_sem").val() );
    formData.append("identity", "FEESLIST");
    formData.append("fee_crse", fee_crse);
    formData.append("fee_year", fee_year);
    formData.append("fee_currncy", fee_currncy);
    formData.append("fee_sem", fee_sem);

    
    $.ajax({
      url: usePath + "fee_list/ajax_process",
      type: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      success: function(resp) {
        if (resp.status) {
          //clear_fee_fields();
          $("#fee_list").html(resp.data);

        } else {
          //showToaster( resp.message);
          $("#fee_list").html('<tr><td colspan="4">No record(s) found.</td></tr>');

        }
      },
      error: function(xhr, status, error) {
        showToast('error', "An error occurred :" + error);

        
      }
    });

  }

  function save_fee_list() {
    var usePath              = $.trim( $("#rootXPath").val() );
    var formData             = new FormData();
    var other_data           = $('form#myforms').serializeArray();
    var mid                  = $.trim( $("#FeelsitId").val() );
  
    $.each(other_data,function(key,input){
      formData.append(input.name,input.value);
    });
    var fee_year      = $.trim( $("#fee_year").val() );
    var fee_crse      = $.trim( $("#fee_crse").val() );
    var fee_catgry      = $.trim( $("#fee_catgry").val() );
    var fee_sem      = $.trim( $("#fee_sem").val() );
    var fee_compt      = $.trim( $("#fee_compt").val() );
    var fee_amt      = $.trim( $("#fee_amt").val() );

    if( fee_year == ''){
      showToast("error","Year is required.");
      setTimeout(function(){ set_global_focus('fee_year');},500);
      return false;
    }else if( fee_crse == ''){
      showToast("error","Course is required.");
      setTimeout(function(){ set_global_focus('fee_crse');},500);
      return false;
    }
    else if( fee_sem == ''){
      showToast("error","Semester is required.");
      setTimeout(function(){ set_global_focus('fee_sem');},500);
      return false;
    }
    else if( fee_compt == ''){
      showToast("error","Component is required.");
      setTimeout(function(){ set_global_focus('fee_compt');},500);
      return false;
    }
    else if( fee_amt == ''){
      showToast("error","Fee Amount is required.");
      setTimeout(function(){ set_global_focus('fee_amt');},500);
      return false;
    }
    formData.append("identity", "FEES");
    formData.append("FeelsitId", mid);
    formData.append("fee_crse", fee_crse); 
    $(".no_loader").removeClass("hidden").addClass("hidden");
    $(".loader").removeClass("hidden");     
    setTimeout(function(){
      $.ajax({
             url: usePath+"fee_list/ajax_process",
             type: 'POST',
             data: formData,
             async: false,
             contentType: false,
             processData: false,
             success: function (resp) {               
                if( resp.status ){         
  
                  $("#fee_list").html(resp.data);
                  $(".no_loader").removeClass("hidden");
                  $(".loader").removeClass("hidden").addClass("hidden"); 
                  showToast("success",resp.message); 
    
                  setTimeout(function(){ reset_feelist_afteradd();},500);         
                         
  
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
  function modify_fee_list(id,year,course,semester,compt,amnt,currncy){
    $("#FeelsitId").val(id);
    $("#fee_year").val(year);
    $("#fee_crse").val(course);
    $("#fee_sem").val(semester) ;
    $("#fee_compt").val(compt);
    $("#fee_amt").val(amnt);
    $("#fee_currncy").val(currncy);
    
  }
  function reset_feelist_afteradd(){
    $("#FeelsitId").val('');
    $("#fee_compt").val('');
    $("#fee_amt").val('');
    $(".process_qualif_save").show();
  }
  
  function clear_fee_fields() {
    $("#fee_year").val('')
    $("#fee_crse").val('');
    $("#fee_sem").val('') ;
    $("#fee_compt").val('');
    $("#fee_amt").val('');
    $("#fee_catgry").val('');
    $("#FeelsitId").val('');
  }
  function delete_fee_list(id){
    var usePath      = $.trim( $("#rootXPath").val() );    
  
    if( confirm("Are you sure you want to delete?")){
        window.location = usePath+"fee_list/add_fee_structure/"+id+"/deletefee";
      }
  
  }


  function alertChecked(url){
    if( confirm("Are you sure want to delete ?")){
        window.location = url
    }
  }

  function process_search_fee(){
    var usePath              = $.trim( $("#rootXPath").val() );
    var formData             = new FormData();
    //var other_data         = $('form#myforms').serializeArray();     
    var course_search           = $.trim( $("#course_search").val() );   
    var year_search              = $.trim( $("#year_search").val() );
  
    formData.append("identity", "FEESSEARCH");
    formData.append("course_search", course_search);
    formData.append("year_search", year_search);
  
      $.ajax({
             url: usePath+"fee_list/ajax_process",
             type: 'POST',
             data: formData,
             async: false,
             contentType: false,
             processData: false,
             success: function (resp) { 
                var ntml = '<tr><td colspan="4">No record(s) found.</td></tr>'          
                if( resp.status ){
                   $("#process_fee_list").html(resp.data);                        
                }else{
                  $("#process_fee_list").html(ntml); 
                }
             },
             error: function () {
                 
             },
             cache: false
     });
  }