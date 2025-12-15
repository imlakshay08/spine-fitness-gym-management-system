# To change this template, choose Tools | Templates
# and open the template in the editor.

class StockreceiptPdf < Prawn::Document
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
     
  move_down 20
  text"<b>Receipt Details </b>", :size => 12 , :align => :center,:inline_format=>:true
  move_down 10
  stroke_horizontal_rule     
 
move_down 40

  data2 = ([
    [{:content => "Receipt No "},  {:content => @voucherdata.Id.to_s}, {:content => ""},{:content => "Receipt Date "},  {:content => formatted_date(@voucherdata.Receipt_prepare_date).to_s}],
  
    [{:content => "Agency Code "},  {:content =>@userDetail.agency.to_s},{:content => ""}, {:content => "Market Name "},  {:content => (  @marketname ? @marketname.City : '').to_s}],
    [{:content => "WD Name "},  {:content => @Wddetail.WDName.to_s},{:content => ""}, {:content => "WD Address "},  {:content => (  @Wddetail ? @Wddetail.Address_1 : '').to_s}],
    [{:content => "Activity Type "},  {:content => @Activitydetail.activity_type.to_s},{:content => ""}, {:content => "Activity Name "},  {:content => (  @Activitydetail ? @Activitydetail.activity_name : '').to_s}],
    [{:content => "Activity Brief Number "},  {:content => @voucherdata.Activity_Brief_Number.to_s},{:content => ""}, {:content => "Segment Type "},  {:content => (  @segmentdetail ? @segmentdetail.seg_description : '').to_s}],
    [{:content => "Brand "},  {:content => @branddetail.Brand_Name.to_s},{:content => ""}, {:content => "Variant "},  {:content => (  @variantdetail ? @variantdetail.vt_description : '').to_s}],
    [{:content => "Pack Size "},  {:content => (  @packsize ? @packsize.ps_packsize : '').to_s},{:content => ""}, {:content => "Date of Pickup "},  {:content => (  @voucherdata ? formatted_date(@voucherdata.Date_of_pickup) : '').to_s}],
    [{:content => "Stock Picked up "},  {:content => (  @voucherdata ? @voucherdata.StockQty_pickup : '').to_s},{:content => ""}, {:content => "Value of Stock "},  {:content => (  @voucherdata ? @voucherdata.Value_for_stock : '').to_s}],
    [{:content => "Rate Per Stick "},  {:content => (  @voucherdata ? @voucherdata.Rate_per_Stick : '').to_s},{:content => ""}, {:content => "Remarks "},  {:content => @voucherdata.Remarks.to_s}],

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

  # data3 = ([
  #   [{:content => "Receipt No "},  {:content => @voucherdata.Id.to_s}],
  #   [{:content => "Receipt Date "},  {:content => formatted_date(@voucherdata.Receipt_prepare_date).to_s}],
  
  #   [{:content => "Agency Code "},  {:content =>@userDetail.agency.to_s}],
  #   [{:content => "Market Name "},  {:content => (  @marketname ? @marketname.City : '').to_s}],
  #   [{:content => "WD Name "},  {:content => @Wddetail.WDName.to_s}],
  #   [{:content => "WD Address "},  {:content => (  @Wddetail ? @Wddetail.Address_1 : '').to_s}],
  #   [{:content => "Activity Type "},  {:content => @Activitydetail.activity_type.to_s}],
  #   [{:content => "Activity Name "},  {:content => (  @Activitydetail ? @Activitydetail.activity_name : '').to_s}],
  #   [{:content => "Activity Brief Number "},  {:content => @voucherdata.Activity_Brief_Number.to_s}],
  #   [{:content => "Segment Type "},  {:content => (  @segmentdetail ? @segmentdetail.seg_description : '').to_s}],
  #   [{:content => "Brand "},  {:content => @branddetail.Brand_Name.to_s}],
  #   [{:content => "Variant "},  {:content => (  @variantdetail ? @variantdetail.vt_description : '').to_s}],
  #   [{:content => "Pack Size "},  {:content => (  @packsize ? @packsize.ps_packsize : '').to_s}],
  #   [{:content => "Date of Pickup "},  {:content => (  @voucherdata ? formatted_date(@voucherdata.Date_of_pickup) : '').to_s}],
  #   [{:content => "Stock Picked up "},  {:content => (  @voucherdata ? @voucherdata.StockQty_pickup : '').to_s}],
  #   [{:content => "Value of Stock "},  {:content => (  @voucherdata ? @voucherdata.Value_for_stock : '').to_s}],
  #   [{:content => "Rate Per Stick "},  {:content => (  @voucherdata ? @voucherdata.Rate_per_Stick : '').to_s}],
  #   [{:content => "Remarks "},  {:content => @voucherdata.Remarks.to_s}],

  # ])
  
  # table([] + data3, :width => 530)do
  # style row(0..1000),  :border_width => 0,:inline_format=>:true
  # style column(0), :width     => 130, :align=>:left, :size => 10
  # style column(1), :width => 400, :size => 10,  :border_bottom_width => 0,:font_style=>:bold
 
  # # cells.padding =4
  # end

move_down 50
  data5 = ([
    [{:content => "Stock Receiver Name "},  {:content => @userDetail.firstname.to_s}, {:content => ""},{:content => ""},  {:content => ""}],
  
    [{:content => "Receiver Designation "},  {:content =>@userDetail.designation.to_s},{:content => ""}, {:content => ""},  {:content => ""}],
    [{:content => "Receiver Mobile No. "},  {:content => @userDetail.phonenumber.to_s},{:content => ""}, {:content => " "},  {:content => ""}],
   
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