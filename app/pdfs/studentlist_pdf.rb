# To change this template, choose Tools | Templates
# and open the template in the editor.
require "open-uri"

class StudentlistPdf < Prawn::Document
    def initialize(studentdetail, compdetail, uRl)
      super(:top_margin=>20,:page_size =>"A4")
      @studentdetail = studentdetail
      @compDetail = compdetail
      @uRl2        = uRl
      @uRl         = Rails.root.join "public"
      @logoSize    = 0.5   
     
      line_items
      
   end
  
   
    def count_mcell
    @count_cell ||= 0
    @count_cell = @count_cell+1
  end
  
  
  def line_items
       
       
    newcompdteail =  @compDetail.cmp_addressline1.to_s+((@compDetail.cmp_addressline1.to_s.length.to_i >1) ? ', ': '' )+@compDetail.cmp_addressline2.to_s+(@compDetail.cmp_addressline3.to_s.strip.length > 1 ? " -#{@compDetail.cmp_addressline3.strip}" : '').to_s
  
          
    if @compDetail.cmp_logos.to_s.length >1
      @filesExt = Rails.root.join "public", "images", "logo",@compDetail.cmp_logos.to_s
      if File.exist?(@filesExt)
        image_path = {:image=>open(@uRl.to_s+"/images/logo/"+@compDetail.cmp_logos.to_s) ,:position =>:right,:fit => [120,50]}           
      else
        image_path =''
      end
   end
   data1 = [ [
      {  :content => "\n<b>#{@compDetail.cmp_companyname}</b>\n#{newcompdteail}\nContact Details : #{@compDetail.cmp_telephonenumber}" +
                    (@compDetail.cmp_email.strip.length > 1 ? ", #{@compDetail.cmp_email.strip}" : ''), :inline_format => true, :size => 10},
      image_path
    ] ]
  
  # Use the repeat method to add the header on every page
   repeat :all do
    bounding_box([bounds.left, bounds.top], :width => 530, :height => 60) do  # Adjust the height as needed for your header
      table(data1, :width => 530) do
        style row(0).column(0..1), :border_width => 0
        style column(0), :width => 330, :align => :left
        style column(1), :width => 200, :align => :right
       end
    end
  end
  

  move_down 10
  text "<b>Student List </b>", :size => 12, :align => :center, :inline_format => true

  bounding_box([bounds.left, bounds.top - 80], width: bounds.width) do
    move_down 10  

   
    data2   = []
    data2 = ([
      [{:content => "S.No. "}, {:content => "Image"}, {:content => "Registration No.\n Date"}, {:content => "Name"}, {:content => "D.O.B\nGender"}, {:content => "NCHM No.\n Course Code"}, {:content => "Mobile No.\n Email"}],
    
    ])

    @studentdetail.each do |student|  
      if student.stdnt_img.present?
        student_image_path = "https://ihm-inqerp.b-cdn.net/#{stid.stdnt_compcode}/student/#{stid.stdnt_img}"
    else
      student_image_path = "#{@uRl}/images/no-image.jpg"
      end

      if student.stdnt_gender == 'M'
        gendername      = "Male"
      elsif student.stdnt_gender == 'F'
        gendername      = "Female"
      elsif student.stdnt_gender == 'Oth'
        gendername      = "Other"
      else
        gendername      = student.stdnt_gender
      end
      data2 += ([
        [{:content => count.to_s}, {:image =>  URI.open(student_image_path.to_s), :fit => [40, 40], :position=>:center}, {:content => student.stdnt_reg_no.to_s+"\n"+formatted_date(student.stdnt_reg_date).to_s }, {:content => student.stdnt_fname.to_s}, {:content => formatted_date(student.stdnt_dob).to_s+"\n"+gendername.to_s}, {:content => student.nhmcno.to_s+"\n"+student.crse_code.to_s}, {:content =>student.stdnt_dtl_cont.to_s+"\n"+student.stdnt_dtl_email.to_s}],
      ])
    end
    table([] + data2, :width => 530)do
    style row(0),:font_style=>:bold,:background_color => 'e7e7e7'
    style column(0), :width     => 40
    style column(1), :width     => 50
    style column(2), :width     => 85
    style column(3), :width     => 110
    style column(4), :width     => 70
    style column(5), :width     => 75
    style column(6), :width     => 100
    style column(0..6),:inline_format => :true, :size => 9
    self.header = true
    # cells.padding =4
   
    end
  end
  
  
      Time.zone = "Kolkata"
      billtimes = Time.zone.now.strftime('%I:%M%p')

      repeat :all do
        fill_color"AAAAAA"
        text_box "Powered By Inquisitor", :inline_format => true, size: 8, align: :left, :at => [bounds.left, bounds.bottom - 10], :height => 100, :width => bounds.width
        
      end
      page_count.times do |i|
        go_to_page(i + 1)  # Navigate to the current page
        move_down 60

        # Combining "Generated on" text with the page number
        text_box "Generated on: #{format_oblig_date(Date.today).to_s} #{billtimes.to_s} | Page: #{i + 1} / #{page_count}", 
                 :font_style => :bold, 
                 :size => 7, 
                 :align => :right, 
                 :at => [bounds.left, bounds.bottom - 10], 
                 :height => 100, 
                 :width => bounds.width
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