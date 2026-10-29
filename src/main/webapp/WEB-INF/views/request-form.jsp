<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Request Blood"/>
    <jsp:param name="nav" value="request"/>
</jsp:include>

<div class="container">
    <div class="card form-card">
        <h2>Request blood</h2>
        <p class="muted">Fill in the details of the patient or hospital. The blood bank reviews every request against
            available stock. You will get a request ID to
            <a href="${ctx}/request-status">track the status</a>.</p>

        <c:if test="${not empty errors}">
            <div class="alert alert-error">
                <ul><c:forEach var="e" items="${errors}"><li><c:out value="${e}"/></li></c:forEach></ul>
            </div>
        </c:if>

        <form action="${ctx}/request-blood" method="post">
            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
            <div class="form-grid">
                <div class="field">
                    <label for="requesterName">Your name</label>
                    <input type="text" id="requesterName" name="requesterName" required minlength="2" maxlength="80"
                           value="<c:out value='${param.requesterName}'/>">
                </div>
                <div class="field">
                    <label for="phone">Mobile number</label>
                    <input type="tel" id="phone" name="phone" required pattern="[0-9]{10}" maxlength="10"
                           value="<c:out value='${param.phone}'/>">
                </div>
                <div class="field">
                    <label for="email">Email <span class="muted">(optional)</span></label>
                    <input type="email" id="email" name="email" maxlength="100" value="<c:out value='${param.email}'/>">
                </div>
                <div class="field">
                    <label for="hospital">Hospital</label>
                    <input type="text" id="hospital" name="hospital" required maxlength="120"
                           value="<c:out value='${param.hospital}'/>">
                </div>
                <div class="field">
                    <label for="bloodGroup">Blood group needed</label>
                    <select id="bloodGroup" name="bloodGroup" required>
                        <option value="">Select</option>
                        <c:forEach var="g" items="${bloodGroups}">
                            <option value="${g}" ${param.bloodGroup == g ? 'selected' : ''}>${g}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="field">
                    <label for="units">Units required</label>
                    <input type="number" id="units" name="units" required min="1" max="10"
                           value="<c:out value='${empty param.units ? 1 : param.units}'/>">
                </div>
                <div class="field">
                    <label for="city">City</label>
                    <input type="text" id="city" name="city" required maxlength="60" value="<c:out value='${param.city}'/>">
                </div>
                <div class="field">
                    <label for="urgency">Urgency</label>
                    <select id="urgency" name="urgency" required>
                        <c:forEach var="u" items="${urgencyLevels}">
                            <option value="${u}" ${param.urgency == u ? 'selected' : ''}>${u}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="field full">
                    <label for="reason">Reason / patient details <span class="muted">(optional)</span></label>
                    <textarea id="reason" name="reason" maxlength="255"><c:out value="${param.reason}"/></textarea>
                </div>
            </div>
            <p style="margin-top:20px"><button type="submit" class="btn">Submit request</button></p>
        </form>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
