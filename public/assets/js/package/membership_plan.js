function alertChecked(url){
    if( confirm("Are you sure want to delete ?")){
        // Submitted as DELETE via a real form rather than window.location.
        // A delete used to be a plain GET, which meant a link prefetcher, a
        // "preload pages" browser setting, or anything that fetches a URL on
        // the admin's behalf could destroy a record without a click.
        var form = document.createElement("form");
        form.method = "post";
        form.action = url;
        form.style.display = "none";

        var m = document.createElement("input");
        m.type = "hidden"; m.name = "_method"; m.value = "delete";
        form.appendChild(m);

        var meta = document.querySelector('meta[name="csrf-token"]');
        if (meta) {
            var t = document.createElement("input");
            t.type = "hidden"; t.name = "authenticity_token"; t.value = meta.getAttribute("content");
            form.appendChild(t);
        }

        document.body.appendChild(form);
        form.submit();
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
  
  $(document).on("keypress","#membership_plan",function(e){
    var keycode = (e.keyCode ? e.keyCode : e.which );
      if( keycode == '13' ){
        filter_membership_plan();
      }
  
  });
  function filter_membership_plan(){
      var useroot = $("#rootXPath").val();
     
      $(".show_loader").removeClass("hidden");
      $(".no_loader").removeClass("hidden").addClass("hidden")
      $("form#myForms").submit(); 
  
  }