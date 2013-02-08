results_directory = '../../sexy_results/';
full_data_directory = '../../data/1d_data_rescaled/';
fold_data_directory = '../../data/1d_extrap_folds/';
figure_directory = '../../figures/extrapolation_curves/';
experiments{1} = '01-airline-s';
experiments{2} = '02-solar-s';
experiments{3} = '03-mauna2003-s';
folds = 10;
percentiles = 100 * (1:(folds-1)) / folds;

for i = 1:length(experiments)
    MSEs.gpss = zeros(folds-1,1);
    MSEs.gpse = zeros(folds-1,1);
    MSEs.lin = zeros(folds-1,1);
    MSEs.gpper = zeros(folds-1,1);
    MSEs.gpadd = zeros(folds-1,1);
    MSEs.gpprod = zeros(folds-1,1);
    for fold = 1:(folds-1)
        fold
        % Load data
        fold_file = [fold_data_directory experiments{i} '-ex-fold-' ...
                     int2str(fold) 'of' int2str(folds) '.mat'];
        load(fold_file);
        X = double(X);
        y = double(y);
        Xtest = double(Xtest);
        ytest = double(ytest);
        % Extract GPSS result
        gpss_file = [results_directory experiments{i} '-ex-fold-' ...
                     int2str(fold) 'of' int2str(folds)  '_predictions.mat'];
        load(gpss_file);
        MSEs.gpss(fold) = mean((actuals - predictions) .^ 2);
        % Fit and score SE GP
        %%%% Random restarts + averaging?
        covfunc = {@covSEiso};
        hyp.cov = [0; 0];
        likfunc = @likGauss;
        hyp.lik = log(std(y));
        meanfunc = {@meanConst};
        hyp.mean = mean(y);
        hyp_opt = minimize(hyp, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        hyp_opt = minimize(hyp_opt, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        [m s2] = gp(hyp_opt, @infExact, meanfunc, covfunc, likfunc,...
                    X, y, Xtest);
        MSEs.gpse(fold) = mean((ytest - m) .^ 2);
        % Fit and score linear model
        %%%% Random restarts + averaging?
        covfunc = {@covSum, {@covConst, @covLINard}};
        hyp.cov = [0; 0];
        likfunc = @likGauss;
        hyp.lik = log(std(y));
        meanfunc = {@meanConst};
        hyp.mean = mean(y);
        hyp_opt = minimize(hyp, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        hyp_opt = minimize(hyp_opt, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        [m s2] = gp(hyp_opt, @infExact, meanfunc, covfunc, likfunc,...
                    X, y, Xtest);
        MSEs.lin(fold) = mean((ytest - m) .^ 2);
        % Fit and score pure periodic
        %%%% Random restarts + averaging?
        covfunc = {@covPeriodic};
        hyp.cov = [0; -2; 0];
        likfunc = @likGauss;
        hyp.lik = log(std(y));
        meanfunc = {@meanConst};
        hyp.mean = mean(y);
        hyp_opt = minimize(hyp, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        hyp_opt = minimize(hyp_opt, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        [m s2] = gp(hyp_opt, @infExact, meanfunc, covfunc, likfunc,...
                    X, y, Xtest);
        MSEs.gpper(fold) = mean((ytest - m) .^ 2);
        % Fit and score pure periodic
        %%%% Random restarts + averaging?
        covfunc = {@covSum, {@covSEiso, @covPeriodic}};
        hyp.cov = [0; 0; 0; -2; 0];
        likfunc = @likGauss;
        hyp.lik = log(std(y));
        meanfunc = {@meanConst};
        hyp.mean = mean(y);
        hyp_opt = minimize(hyp, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        hyp_opt = minimize(hyp_opt, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        [m s2] = gp(hyp_opt, @infExact, meanfunc, covfunc, likfunc,...
                    X, y, Xtest);
        MSEs.gpadd(fold) = mean((ytest - m) .^ 2);
        % Fit and score pure periodic
        %%%% Random restarts + averaging?
        covfunc = {@covProd, {@covSEiso, @covPeriodic}};
        hyp.cov = [0; 0; 0; -2; 0];
        likfunc = @likGauss;
        hyp.lik = log(std(y));
        meanfunc = {@meanConst};
        hyp.mean = mean(y);
        hyp_opt = minimize(hyp, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        hyp_opt = minimize(hyp_opt, @gp, -300, @infExact, ...
                   meanfunc, covfunc, likfunc, X, y);
        [m s2] = gp(hyp_opt, @infExact, meanfunc, covfunc, likfunc,...
                    X, y, Xtest);
        MSEs.gpprod(fold) = mean((ytest - m) .^ 2);
    end
    
    semilogy(percentiles, MSEs.gpss, 'LineWidth', 2);
    hold on
    semilogy(percentiles, MSEs.gpse, 'g', 'LineWidth', 2);
    semilogy(percentiles, MSEs.lin, 'r', 'LineWidth', 2);
    semilogy(percentiles, MSEs.gpper, 'y', 'LineWidth', 2);
    semilogy(percentiles, MSEs.gpadd, 'c', 'LineWidth', 2);
    semilogy(percentiles, MSEs.gpprod, 'm', 'LineWidth', 2);
    xlabel('Proportion training data (%)');
    ylabel('MSE');
    legend('Structure search', 'SE GP', 'Linear', 'Per GP', 'SE + Per GP', 'SE x Per GP', 'location', 'best');
    hold off
    saveas( gcf, [figure_directory experiments{i} '-ex-curve.fig'] );
    save2pdf( [figure_directory experiments{i} '-ex-curve.pdf'], gcf, 600, true );
end