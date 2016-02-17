function [q_int] = load_profile(start_time, length, Z, tents)
% 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% 
% 
%   Author: Grant Gunnison
% 
%   This program will generate a random internal load profile for the
%   tend that will represent thermal input due to various devices: people,
%   equipment or short external atmospheric inputs due the tent opening
%   during any time during the day.
% 
% 
%   Assumptions:
% 
%   1) All inputs create instantaneous change
%   2) Each person has the same load profile 
% 
%   Inputs:
%   start_time - given in epoch time                  (s)
%   length     - Length of load profile forecast      (s)
%   Z          - Number of tents    
%   tents      - List of the quantity of each type of tent
%                in given order
%                ["sleep", "kitchen", "headquarters"]
%     
% 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    close all;
    time_reference = datenum('1970', 'yyyy'); 
    datetime = time_reference + start_time / 8.64e7;
    hour = str2num(datestr(datetime, 'HH'));
    minute = str2num(datestr(datetime, 'MM'));

    person = 100; % Amount of heat a person produces (W)

    num_sleep = tents(1);
    num_kitchen = tents(2);
    num_head = tents(3);



    % Generate loads 
    q_int = ones(length, Z);
    for step = 1:length

        sleep = sleep_tent(hour, minute, person);
        kitchen = kitchen_tent(hour, person);
        head = headquarter_tent(hour, person);

%         disp(horzcat(ones(1, num_sleep)*sleep, ones(1, num_kitchen)*kitchen, ones(1, num_head)*head))
        q_int(step, 1:Z) = horzcat(ones(1, num_sleep)*sleep, ones(1, num_kitchen)*kitchen, ones(1, num_head)*head);
    
        minute = minute +1;
        if (minute == 60)
            minute = 0;
            hour = hour + 1;
        if (hour == 24)
            hour = 0;
        end
        end
    end
end


% Sleeping Tent Model
% 
% From hours 8-10pm load ramps up
% From hours 10pm - 6am constant load 
% From hours 6am - 8am load ramps down
% 
% Each tent can hold up to 20 people, but our tents will vary 15-20 people

function [sleep_load] = sleep_tent(hour, minute, person)

    num_people = 15 + round(rand(1)/.18);


    if (hour >= 22) || (hour <= 6)
        sleep_load = num_people*person;
    elseif (hour == 6)
        sleep_load = (num_people - num_people*(minute)/120)*person;
    elseif (hour == 7)
        sleep_load = (num_people - num_people*(minute + 60)/120)*person;
    elseif (hour == 20)
        sleep_load = num_people*minute/120*person;
    elseif (hour == 21)
        sleep_load = num_people*(minute+60)/120*person;
    else
        sleep_load = 0;
    end
    
    
end

% Kitchen Tent Model
% 
% From hours 6am - 9am, 11am-2pm and 5-8pm model have a large load
% 
% For hours outside of above but between 5am - 10pm model will have a small
% internal load for kitchen staff
% 
% Each kitchen tent will also be able to hold up to 20 people

function [kitchen_load] = kitchen_tent(hour, person)

    num_people = 15 + round(rand(1)/.18);

    if (hour >= 6) && (hour <= 9) || (hour >=11 && hour <= 14) || (hour >= 17 && hour <= 19)
        kitchen_load = num_people*person;
    elseif (hour >= 5 && hour <= 22)
        kitchen_load = 3*person;
    else
        kitchen_load = 0;
    end
end

% Headquarters Tent Model
% 
% From hours 7am - 8pm model will have a varying high load 
% From hours 8pm - 7am model will have a constant low load
function [head_load] = headquarter_tent(hour, person)

    num_people = 10 + round(rand(1)/.18);

    if (hour >=7 && hour <20)
        head_load = num_people*person;
    else
        head_load = 2*person;
    end
end