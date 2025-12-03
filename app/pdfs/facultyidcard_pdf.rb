# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'net/http'
require "open-uri"
class FacultyidcardPdf < Prawn::Document
  def initialize(reportdata, compdetail, uRl)
    super(:left_margin=>5,:right_margin=>5,:top_margin=>5,:bottom_margin=>2,:page_size =>[243, 153])
    @reportdata = reportdata
    @compDetail = compdetail
    @uRl2        = uRl
    @uRl         = Rails.root.join "public"
    @logoSize    = 0.2   
   
    line_items
    
 end

 
  def count_mcell
  @count_cell ||= 0
  @count_cell = @count_cell+1
end


def line_items
  # newcompdteail =  @compDetail.cmp_addressline1.to_s+((@compDetail.cmp_addressline1.to_s.length.to_i >1) ? ', ': '' )+@compDetail.cmp_addressline2.to_s+(@compDetail.cmp_addressline3.to_s.strip.length > 1 ? " -#{@compDetail.cmp_addressline3.strip}" : '').to_s
  newcompdteail = "Library Avenue, Pusa, New Delhi-110012"
  if @compDetail.cmp_logos.to_s.length >1
    @filesExt = Rails.root.join "public", "images", "logo",@compDetail.cmp_logos.to_s
    if File.exist?(@filesExt)
      image_path = {:image=>open(@uRl.to_s+"/images/logo/"+@compDetail.cmp_logos.to_s) ,:position =>:center,:fit => [35,35],:rowspan=>2}           
    else
      image_path =''
    end
 
 end

 if @compDetail.cmp_signs.to_s.length >1
  @signfilesExt = Rails.root.join "public", "images", "signs",@compDetail.cmp_signs.to_s
  if File.exist?(@signfilesExt)
    principal_image_path = {:image=>open(@uRl.to_s+"/images/signs/"+@compDetail.cmp_signs.to_s) ,:position =>:center,:fit => [35,20],:rowspan=>3}           
  else
    principal_image_path = {:image=>open(@uRl.to_s+"/assets/img/invoice_logo.png") ,:position =>:center,:fit => [35,20],:rowspan=>3} 
  end

end

  # student_image_path = {:image=>open(@uRl.to_s+"/assets/img/user/user10.jpg") ,:position =>:left,:fit => [48,80],:rowspan=>5,:padding_top=>4}           
 

data2 = []
record_count = 0
  @reportdata.each.map do |stid|
    data1 = ([ 
   [{:content => "<b>INSTITUTE OF HOTEL MANAGEMENT CATERING & NUTRITION</b>", :inline_format => true, :size => 7.7,:padding_bottom=>2,:colspan=>2,:text_color => '010193',:font_style=>:bold}],
  # [image_path,{:content => "<b>Pusa, New Delhi-110012</b>", :inline_format => true, :size => 7,:padding_top=>0,:padding_bottom=>1,:text_color => 'DC143C',:font_style=>:bold}],
  [image_path,{:content => "<b>(An autonomous body under Ministry of Tourism, Govt. of India)</b>", :inline_format => true, :size => 6.5,:padding_top=>0,:text_color => '010193',:font_style=>:bold}],
  [{:content => "<b><u>Identity Card</u></b>", :inline_format => true, :size=>7.8,:padding_top=>0}],
 
    
   ])

# Use the repeat method to add the header on every page
 
    table(data1, :width => 240) do
      style row(0..3).column(0..1), :border_width => 0
      style column(0), :width => 30, :align => :center, :inline_format => :true
      style column(1), :width => 210, :align => :center
      cells.padding = [0,3,0,0]
     end
     if stid.fclty_img.present?
      student_image_path = "https://ihm-inqerp.b-cdn.net/#{stid.fclty_compcode}/faculty/#{stid.fclty_img}"
      
      # Function to check if the URL for the image file is valid
      def url_exists?(url)
        uri = URI.parse(url)
        response = Net::HTTP.get_response(uri)
        response.code == "200" # Returns true if status is 200 (OK)
      end
    
      # Verify if the image URL exists
      unless url_exists?(student_image_path)
        student_image_path = "#{@uRl}/images/no-image.jpg" # Use default if the image is not found on the server
      end
    else
      student_image_path = "#{@uRl}/images/no-image.jpg" # Fallback if no image in the database
    end
    
    # file_extension = File.extname(stid.stdnt_signature).downcase if stid.stdnt_signature.present?

    # if stid.stdnt_signature.present? 
    #   student_signature_path = "https://ihm-inqerp.b-cdn.net/#{stid.stdnt_compcode}/studentsign/#{stid.stdnt_signature}"
    # else
    #   student_signature_path = "#{@uRl}/images/no-image.jpg"
    # end
    
    file_extension = File.extname(stid.fclty_signature).downcase if stid.fclty_signature.present?

    # Function to check if the URL for the image file is valid
    def sign_url_exists?(url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      response.code == "200" # Returns true if status is 200 (OK)
    end
    
    if stid.fclty_signature.present? && !['.pdf', '.heic'].include?(file_extension)
      faculty_signature_path = "https://ihm-inqerp.b-cdn.net/#{stid.fclty_compcode}/facultysign/#{stid.fclty_signature}"
    
      # Verify if the image URL exists
      unless sign_url_exists?(faculty_signature_path)
        faculty_signature_path = "#{@uRl}/images/no-image.jpg" # Use default if the image is not found on the server
      end
    else
      faculty_signature_path = "#{@uRl}/images/no-image.jpg"
    end
    
    move_down 2
  data2 = ([
       [{:image =>  URI.open(student_image_path.to_s),:position =>:left,:fit => [47,50],:rowspan=>5,:padding_top=>4},{:content=>"AEBAS Id"},{:content=>":"},{:content=>stid.fclty_aebas_id.to_s}],
    
     
      ])
            

    table([] + data2,:width =>235)  do
    
    style column(0..7),:inline_format=>:true ,  :border_width => 0,:size=>7,:font_style=>:bold
    # style row(0),  :size => 9, :align=>:center
    style row(0..1).column(0), width: 48  # Image column
    style row(0..1).column(1), width: 55  # "Roll No." column
    style row(0..1).column(2), width: 10  # ":" column
     style row(0..1).column(3), width: 122  #
 
    style row(1),:border_bottom_width =>1, :padding => [1, 1, 2, 1]
    style row(0), :padding => [0, 1, 1, 1]
    # style row(0).column(0),:border_width => 1 
    # cells.padding = 2
    end
    
        
  data3 = ([
    ['',{:content=>"<b>Name</b>"},{:content=>":"},{:content=>"<b>"+stid.fclty_name.to_s+"</b>",:colspan=>3}],
    ['',{:content=>"<b>Father's Name</b>"},{:content=>":"},{:content=>stid.fclty_father.to_s,:colspan=>3}],
    ['',{:content=>"<b>Designation</b>"},{:content=>":"},{:content=>stid.fclty_desig.to_s,:colspan=>3}],
    ['',{:content=>"<b>Date of Birth</b>"},{:content=>":"},{:content=>format_oblig_date(stid.fclty_dob).to_s,:colspan=>2}],
    [{:image =>  URI.open(faculty_signature_path.to_s),:position =>:center,:fit => [35,20],:rowspan=>3},{:content=>"<b>Employee Code</b>"},{:content=>":"},{:content=>stid.fclty_employee_code.to_s,:colspan=>2},principal_image_path],
    [{:content=>"<b>Blood Group</b>"},{:content=>":"},{:content=>stid.fclty_blood_group,:colspan=>2}],
  
   ])
         

 table([] + data3,:width =>235)  do
 
 style column(0..5),:inline_format=>:true ,  :border_width => 0,:size=>7.2,:font_style=>:bold
 # style row(0),  :size => 9, :align=>:center
 style column(0), width: 48  # Image column
 style column(1), width: 55  
 style column(2), width: 10  # ":" column
 style column(3), width: 82 
 style column(4), width: 40 

 cells.padding = 0.8
 end

  
        
 data4 = ([
 [{:content=>""},{:content=>"<b>Issuing Authority</b>",:align => :right}],
  [{:content=>"<b>Signature of Cardholder</b>"},{:content=>"<b>Principal & Member Secretary</b>",:align => :right}],
 ])
       

table([] + data4,:width =>235)  do

style column(0..4),:inline_format=>:true ,  :border_width => 0,:size=>7.2,:font_style=>:bold
style column(0), width: 120  
style column(1), width: 115  

cells.padding = [0,2,0,0]
end
    # IC CARD BACK SIDE START  
# data5 = ([
#   [{:content=>"<b>IHM Pusa - "+stid.fclty_name.to_s+" - "+stid.fclty_aebas_id.to_s+"</b>"}],
 
#  ])
       

# table([] + data5,:width =>235)  do

# style column(0),:inline_format=>:true ,  :border_width => 0,:size=>8,:font_style=>:bold,:align=>:center,:text_color => 'DC143C'
# style column(0), width: 235  

# cells.padding = 1
# end

data6 = ([
  [{:content=>"<b>Resi. Address</b>"},{:content=>":"},{:content=>(stid.fclty_addr1.present? ? stid.fclty_addr1.to_s : '').to_s+(stid.fclty_addr2.present? ? ", "+stid.fclty_addr2.to_s : '').to_s+(stid.fclty_city.present? ? ", "+stid.fclty_city.to_s : '').to_s,:height=>20}],
 
 ])
       

table([] + data6,:width =>235)  do

style column(0..5),:inline_format=>:true ,  :border_width => 0,:size=>7.3,:font_style=>:bold
 # style row(0),  :size => 9, :align=>:center
 style column(0), width: 55  # Image column
 style column(1), width: 10  
 style column(2), width: 170  
cells.padding = 1
end

data7 = ([
  [{:content=>"<b>Contact No.</b>"},{:content=>":"},{:content=>(stid.fclty_contact.present? ? stid.fclty_contact.to_s+" (M)" : '').to_s+(stid.fclty_emergency_no.present? ? ", "+stid.fclty_emergency_no.to_s+" (R)" : '').to_s}],
   [{:content=>"<b>Date of Joining </b>"},{:content=>":"},{:content=>format_oblig_date(stid.fclty_join_date).to_s}],
     [{:content=>"<b>CGHS Beneficiary Id</b>"},{:content=>":"},{:content=>stid.fclty_cghs_id.to_s}],
     [{:content=>"<b>Valid Upto</b>"},{:content=>":"},{:content=>stid.fclty_valid_upto.to_s}],
 
 ])
       

table([] + data7,:width =>235)  do

style column(0..5),:inline_format=>:true ,  :border_width => 0,:size=>7.3,:font_style=>:bold
 # style row(0),  :size => 9, :align=>:center
 style column(0), width: 80  # Image column
 style column(1), width: 10  
 style column(2), width: 145  
cells.padding = 1
end

move_down 5

text "<b>This card is to be displayed by the official while on duty. In case of retirement or transfer of the official to other department, it should be surrendered.</b>",:align=> :left,:size=>6.3,:font_style=>:bold,:inline_format=>:true


       
 data9 = ([
   [{:content=>""},principal_image_path],
 ])
  

table([] + data9,:width =>235)  do

style column(0..1),:inline_format=>:true ,  :border_width => 0,:size=>7,:font_style=>:bold
style column(0), width: 155  
style column(1), width: 80  

cells.padding = 0
end

 data10 = ([
   [{ content: ""}, { content: "<b>Issuing Authority</b>", align: :right }],
 ])
  

table([] + data10,:width =>235)  do

style column(0..1),:inline_format=>:true ,  :border_width => 0,:size=>7,:font_style=>:bold
style column(0), width: 155  
style column(1), width: 80  

cells.padding = [0,2,2,0]
end


fill_color '010193'
text "<b>INSTITUTE OF HOTEL MANAGEMENT CATERING & NUTRITION</b>",:align=> :center,:size=>7.3,:inline_format=>:true,:text_color => '010193'

text "<b>#{newcompdteail}</b>",:align=> :center,:size=>7.2,:inline_format=>:true,:text_color => '010193'
text "<b>Ph : #{@compDetail.cmp_telephonenumber}</b>",:align=> :center,:size=>7.2,:inline_format=>:true,:text_color => '010193'
fill_color '000000'
# IC CARD BACK SIDE END  
    record_count += 1

    # Start a new page if it's not the last record
    if record_count != @reportdata.size
      start_new_page
    end
    
 end
    Time.zone = "Kolkata"
    billtimes = Time.zone.now.strftime('%I:%M%p')

  
   
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