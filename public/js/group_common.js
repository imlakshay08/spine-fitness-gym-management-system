$("#from_dated").click(function() {
$(this).datepick({ dateFormat: "dd-M-yyyy" }).datepick("show");
});
 
$("#firstdate").click(function() {
$(this).datepick({ dateFormat: "dd-M-yyyy" }).datepick("show");
});

$("#lastdate").click(function() {
$(this).datepick({ dateFormat: "dd-M-yyyy" }).datepick("show");
});

$("#upto_dated").click(function() {
   $(this).datepick({ dateFormat: "dd-M-yyyy" }).datepick("show");
});


$("#frompse_dated").click(function() {
$(this).datepick({ dateFormat: "dd-M-yyyy" }).datepick("show");
});

$("#myfrom_dated").click(function() {
$(this).datepick({ dateFormat: "dd-M-yyyy" }).datepick("show");
});


$("#myupto_dated").click(function() {
$(this).datepick({ dateFormat: "dd-M-yyyy" }).datepick("show");
});


// DICE JS START

let dice = document.getElementById('dice');
var outputDiv = document.getElementById('diceResult');

function rollDice() {
    let result = Math.floor(Math.random() * (6 - 1 + 1)) + 1;
    dice.dataset.side = result;
    dice.classList.toggle("reRoll");

    console.log(result);
  
    outputDiv.classList.remove("reveal");
    outputDiv.classList.add("hide");
    outputDiv.innerHTML = "You've got " + result;
    setTimeout(function(){ outputDiv.classList.add("reveal"); }, 30000);
}

dice.addEventListener("click", rollDice);

// DICE JS END
