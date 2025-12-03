# To change this template, choose Tools | Templates
# and open the template in the editor.

class PackreturnPdf < Prawn::Document
  def initialize(voucherdata,uRl,userDetail,marketname,wddetail,activitydetail,segmentdetail,branddetail,variantdetail,packsize)
    super(:top_margin=>15,:page_size =>"A4")
    @voucherdata = voucherdata
    @uRl2        = uRl
    @uRl         = Rails.root.join "public"
    @userDetail  = userDetail
    @marketname  = marketname
    @Wddetail    = wddetail
    @Activitydetail = activitydetail
    @segmentdetail  = segmentdetail
    @branddetail    = branddetail
    @variantdetail  = variantdetail
    @packsize       = packsize
    @logoSize    = 0.5   
   
    line_items
    
 end

 
  def count_mcell
  @count_cell ||= 0
  @count_cell = @count_cell+1
end


def line_items
  stroke do
    # Draw vertical lines
    vertical_line 0, 780, at: 0
    vertical_line 0, 780, at: 523 
    
    # Draw horizontal lines
    horizontal_line 0, 523, at: 0
    horizontal_line 0, 523, at: 780
  end
  
  move_down 20
  text"<b>EMPTY PACK SUBMISSION RECIEPT </b>", :size => 11 , :align => :center,:inline_format=>:true
  move_down 10
  stroke_horizontal_rule     
  move_down 20
  text"<b><u> To Whom So Ever It May Concern </u></b>", :size => 14 , :align => :center,:inline_format=>:true
  move_down 20


  data2 = ([
    
    [{:content => "Date "},  {:content =>formatted_date(@voucherdata.Date_of_pickup).to_s},{:content => ""}, {:content => "City "},  {:content => (  @marketname ? @marketname.City : '').to_s}],
    [{:content => "WD Name "},  {:content => @Wddetail.WDName.to_s},{:content => ""}, {:content => "WD Code "},  {:content => (  @Wddetail ? @Wddetail.WDCode : '').to_s}],
    [{:content => "Activity Type "},  {:content => @Activitydetail.activity_type.to_s},{:content => ""}, {:content => "Activity Name "},  {:content => (  @Activitydetail ? @Activitydetail.activity_name : '').to_s}],
  
  ])
  
  table([] + data2, :width => 530)do
  style row(0..1000),  :border_width => 0,:inline_format=>:true
  style column(0), :width     => 110, :align=>:left, :size => 10
  style column(1), :width => 145, :size => 10,  :border_bottom_width => 0,:font_style=>:bold
  style column(2), :width     => 30, :size => 10
  style column(3), :width     => 90, :size => 10
  style column(4), :width     => 155, :size => 10,  :border_bottom_width => 0,:font_style=>:bold
  # cells.padding =4
  end
  move_down 30
  text"<b>This is to certify that Below Mentioned Empty Packs Are Submited at our WD Point By MAX PSP Team </b>", :size => 10 , :align => :center,:inline_format=>:true

  move_down 30
  data3 = ([
   
    [{:content => "Brand "},  {:content => @branddetail.Brand_Name.to_s},{:content => ""}, {:content => "Variant "},  {:content => (  @variantdetail ? @variantdetail.vt_description : '').to_s}],
    [{:content => "Pack Size "},  {:content => (  @packsize ? @packsize.ps_packsize : '').to_s},{:content => ""}, {:content => ""},  {:content => ""}],
    [{:content => "Total No. of Empty Packs Submited "},  {:content => (  @voucherdata ? @voucherdata.StockQty_pickup : '').to_s},{:content => ""}, {:content => " "},  {:content => ""}],
   

  ])
table([] + data3, :width => 530)do
style row(0..1000),  :border_width => 0,:inline_format=>:true
style column(0), :width     => 180, :align=>:left, :size => 10
style column(1), :width => 110, :size => 10,  :border_bottom_width => 0,:font_style=>:bold
style column(2), :width     => 30, :size => 10
style column(3), :width     => 90, :size => 10
style column(4), :width     => 120, :size => 10,  :border_bottom_width => 0,:font_style=>:bold
# cells.padding =4
end


move_down 50
  data5 = ([
    [{:content => "<b>Submited By</b>"},  {:content =>""},{:content => ""}, {:content => "<b>Received By</b>"},  {:content => ""}],
    [{:content => "Name :"},  {:content => @voucherdata.Stock_receiver_Name.to_s}, {:content => ""},{:content => "Name :"},  {:content => ""}],
    [{:content => " Mobile No. :"},  {:content => @voucherdata.Stock_receiver_MobileNo.to_s},{:content => ""}, {:content => "Mobile No. :"},  {:content => ""}],
    [{:content => " Designation :"},  {:content =>@voucherdata.Stock_receiver_Designation.to_s},{:content => ""}, {:content => "Designation :"},  {:content => ""}],
    [{:content => " "},  {:content =>""},{:content => ""}, {:content => "Signature :"},  {:content => ""}],
  
   
  ])
  
  table([] + data5, :width => 530)do
  style row(0..1000),  :border_width => 0,:inline_format=>:true
  style column(0), :width     => 110, :align=>:left, :size => 10
  style column(1), :width => 145, :size => 10,  :border_bottom_width => 0,:font_style=>:bold
  style column(2), :width     => 30, :size => 10
  style column(3), :width     => 90, :size => 10
  style column(4), :width     => 155, :size => 10,  :border_bottom_width => 0,:font_style=>:bold
  # cells.padding =4
  end

  move_down 50
  text "#{Prawn::Text::NBSP*2} WD Stamp with Receiver Signature", :size => 10 , :align => :left,:inline_format=>:true


  move_down 70
  text "#{Prawn::Text::NBSP*2} <b>Remarks If Any :</b>", :size => 10 , :align => :left,:inline_format=>:true

  move_down 10
  


    Time.zone = "Kolkata"
    billtimes = Time.zone.now.strftime('%I:%M%p')
    
    
    repeat :all do
     
      text_box "Generated on : "+format_oblig_date(Date.today).to_s+" "+billtimes.to_s ,:font_style=>:bold, :size => 7, align: :right, :at => [bounds.left, bounds.bottom-10], :height => 100, :width => bounds.width
      
    end
   
  end
  
  
  
  private
  def format_oblig_date(dates)
       newdate = ''
       if dates!=nil && dates!=''
            dts    = Date.parse(dates.to_s)
            newdate = dts.strftime("%d/%m/%Y")
       end
       return newdate
  end
  
private
def number_currency_in_words
   to_words(@tnetamt.to_f)  
 end

private
   def currency_formatted(amt)
        amts = ''
        if amt!=nil && amt!=''
          amts = "%.2f" % amt.to_f
        end
        return amts
   end

private
 def formatted_date(dates)
      newdate = ''
      if dates!=nil && dates!=''
           dts    = Date.parse(dates.to_s)
           newdate = dts.strftime("%d-%b-%Y")
      end
      return newdate
 end

def count
  @count ||= 0
  @count = @count+1
end


def to_words(num)
  numbers_to_name = {
      10000000 => "Crore",
      100000 => "Lakh",
      1000 => "Thousand",
      100 => "Hundred",
      90 => "Ninety",
      80 => "Eighty",
      70 => "Seventy",
      60 => "Sixty",
      50 => "Fifty",
      40 => "Forty",
      30 => "Thirty",
      20 => "Twenty",
      19=>"Nineteen",
      18=>"Eighteen",
      17=>"Seventeen",
      16=>"Sixteen",
      15=>"Fifteen",
      14=>"Fourteen",
      13=>"Thirteen",
      12=>"Twelve",
      11 => "Eleven",
      10 => "Ten",
      9 => "Nine",
      8 => "Eight",
      7 => "Seven",
      6 => "Six",
      5 => "Five",
      4 => "Four",
      3 => "Three",
      2 => "Two",
      1 => "One"
    }

  log_floors_to_ten_powers = {
    0 => 1,
    1 => 10,
    2 => 100,
    3 => 1000,
    4 => 1000,
    5 => 100000,
    6 => 100000,
    7 => 10000000
  }

  num = num.to_i
  return '' if num <= 0 or num >= 100000000

  log_floor = Math.log(num, 10).floor
  ten_power = log_floors_to_ten_powers[log_floor]

  if num <= 20
    numbers_to_name[num]
  elsif log_floor == 1
    rem = num % 10
    [ numbers_to_name[num - rem], to_words(rem) ].join(' ')
  else
    [ to_words(num / ten_power), numbers_to_name[ten_power], to_words(num % ten_power) ].join(' ')
  end
end
end