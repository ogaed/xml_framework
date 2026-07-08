module XmlFramework
  module Views
    class JasperRenderer
      def initialize(engine)
        @engine = engine
      end

      def render(jasper, view_key)
        report = jasper[:reportfile] || jasper[:name]
        filtered = jasper[:filtered].to_s == 'true'

        params_form = if filtered
                        <<~HTML
                          <form class="jasper-params-form mb-3" data-report="#{h(report)}" data-view="#{h(view_key)}">
                            <div class="row g-2">
                              <div class="col-md-4">
                                <label class="form-label">From Date</label>
                                <input type="date" name="date_from" class="form-control" />
                              </div>
                              <div class="col-md-4">
                                <label class="form-label">To Date</label>
                                <input type="date" name="date_to" class="form-control" />
                              </div>
                              <div class="col-md-4 d-flex align-items-end">
                                <button type="submit" class="btn btn-primary w-100">Generate Report</button>
                              </div>
                            </div>
                          </form>
                        HTML
                      else
                        <<~HTML
                          <button type="button" class="btn btn-primary jasper-generate-btn"
                                  data-report="#{h(report)}" data-view="#{h(view_key)}">
                            <i class="fa fa-file-pdf"></i> Generate Report
                          </button>
                        HTML
                      end

        <<~HTML
          <div class="jasper-report card">
            <div class="card-header">
              <strong>#{h(jasper[:name] || report)}</strong>
            </div>
            <div class="card-body">
              #{params_form}
              <div id="jasper-output" class="jasper-output mt-3"></div>
            </div>
          </div>
        HTML
      end

      private

      def h(v)
        ERB::Util.html_escape(v.to_s)
      end
    end
  end
end
