 % Button pushed function: Measurex0zButton
        function Measurex0zButtonPushed(app, event)

            % Connexion avec libre vna
            host = '127.0.0.1';
            port = 19542;
            scpi = tcpclient(host, port, "Timeout", 30);

            theta = [-180:app.sampling_theta:180-app.sampling_theta];

            %Move motor to phi=0deg
            angle = num2str(app.offset_angle);
            data2send=strcat('M',angle ,'D')
            write(app.s, data2send, "char");

            % sET First Polar
            % Write the port to the serial port
            data2send='!';
            write(app.s, data2send, "char");
            pause(app.delay_s);

            app.PortEditField.Value=0;
            p=1;

            for c = 0:1:2*length(theta)-1

                % Lancement et lecture de S21
                writeline(scpi, "VNA:TRACe:DATA? S21");
                raw= readline(scpi);
                pause(0.5);
                raw = erase(raw, ["[", "]"]);
                nums = str2double(split(raw, ","));

                data = reshape(nums, 3, []).';
                freqs = data(:,1);
                S21_Re = data(:,2);
                S21_Im = data(:,3);

                % Separation Etheta et Ephi
                if(mod(c,24) < 12)
                    Eth= S21_Re + 1i*S21_Im;
                    Etheta(p,mod(c,24)+floor(c/24)*12+1,:)= Eth;
                    plot(app.UIAxes,freqs,20*log10(abs(Eth)),'b')
                else
                    Eph= S21_Re + 1i*S21_Im;
                    Ephi(p,-12+mod(c,24)+floor(c/24)*12+1,:)= Eph;
                    plot(app.UIAxes,freqs,20*log10(abs(Eph)),'r')

                end

                % Write the port to the serial port
                data2send='$';
                write(app.s, data2send, "char");
                pause(app.delay_s);
                app.PortEditField.Value= app.PortEditField.Value+1;

                fprintf('%d',mod(c,10))
                if(app.ThetaSampDropDown.Value == '20')

                    % Write the port to the serial port
                    data2send='$';
                    write(app.s, data2send, "char");
                    % Pause for a moment to wait for a response

                    pause(app.delay_s);
                    app.PortEditField.Value= app.PortEditField.Value+1;
                end

                app.Gauge.Value = 100*(c)/(length(theta)*2);

            end
            pause(app.delay_s);

            % app.LLamp.Color = 'green';
            app.Gauge.Value = 0;

            % add 360° theta values
            Etheta(:,length(theta)+1,:) = Etheta(:,1,:);
            Ephi(:,length(theta)+1,:)  =  Ephi(:,1,:) ;

            % Set as default measurement
            app.Ephi=Ephi;
            app.Etheta=-Etheta;  %Etheta is opposite direction // it was in the NF algo before
            app.sampling_phi = 0;
            app.sampling_theta = str2double(app.ThetaSampDropDown.Value);
