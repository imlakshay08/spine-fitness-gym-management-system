module ApplicationHelper
     def plan_badge_color(plan_name)
    case plan_name.to_s.downcase
    when 'monthly'     then '#42a5f5'
    when 'quarterly'   then '#ab47bc'
    when 'half-yearly' then '#ffa726'
    when 'yearly'      then '#26a69a'
    when 'open'        then '#78909c'
    else '#607d8b'
    end
  end

end
